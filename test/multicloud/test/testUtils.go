package test

import (
	"bufio"
	"context"
	"encoding/base64"
	"fmt"
	"io"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/wait"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func buildClientSet(config *rest.Config) (*kubernetes.Clientset, error) {
	// Create a Kubernetes client
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, err
	}
	return clientset, nil
}

// Create a Bearer token REST config
func createRESTConfigWithBearer(caCert, bearerToken, host string) *rest.Config {
	config := &rest.Config{
		Host:        host,
		BearerToken: bearerToken,
		TLSClientConfig: rest.TLSClientConfig{
			CAData: []byte(caCert),
		},
	}
	return config
}

// Create REST config with client cert and key
func createRESTConfigWithClientCert(caCert, clientCert, clientKey, host string) *rest.Config {
	config := &rest.Config{
		Host: host,
		TLSClientConfig: rest.TLSClientConfig{
			CAData:   []byte(caCert),
			CertData: []byte(clientCert),
			KeyData:  []byte(clientKey),
		},
	}
	return config
}

func testClusterAccess(t *testing.T, clientset *kubernetes.Clientset) {
	// Test the cluster is accessible by listing nodes
	_, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		t.Fatalf("Failed to list nodes: %v", err)
	}
	// Test the cluster is accessible by listing namespaces
	_, err = clientset.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		t.Fatalf("Failed to list namespaces: %v", err)
	}
}

func checkLogsForErrors(logs io.ReadCloser) error {
	scanner := bufio.NewScanner(logs)
	for scanner.Scan() {
		line := scanner.Text()
		// print a debug line
		fmt.Printf("Log line: %s\n", line)
		// Check if the line contains the word "error"
		if strings.Contains(strings.ToLower(line), "error") {
			// create a new error with the log line
			return fmt.Errorf("Error found in logs: %s", line)
		}
	}
	// Check for any scanner errors
	if err := scanner.Err(); err != nil {
		return err
	}
	return nil
}

func checkRetinaLogs(t *testing.T, clientset *kubernetes.Clientset) {
	// Get the logs for the retina pods
	pods, err := clientset.CoreV1().Pods("kube-system").List(context.TODO(), metav1.ListOptions{
		LabelSelector: "k8s-app=retina",
	})
	if err != nil {
		t.Fatalf("Failed to list pods: %v", err)
	}
	// Stream the logs for each pod
	for _, pod := range pods.Items {
		// Get the logs for the pod
		req := clientset.CoreV1().Pods("kube-system").GetLogs(pod.Name, &v1.PodLogOptions{})
		// Stream the logs
		logs, err := req.Stream(context.Background())
		if err != nil {
			t.Fatalf("Failed to get logs for pod %s: %v", pod.Name, err)
		}
		// Check the logs for errors
		err = checkLogsForErrors(logs)
		if err != nil {
			t.Fatalf("Failed to check logs for errors: %v", err)
		}
		// Close the logs stream
		logs.Close()
	}
}

// function to convert base64 encoded string to plain text
func decodeBase64(t *testing.T, encoded string) string {
	// decode the base64 encoded string
	decoded, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		t.Fatalf("Failed to decode base64 string %v:", err)
	}
	// return the decoded string
	return string(decoded)
}

// fetch the sensitive output from OpenTofu
func fetchSensitiveOutput(t *testing.T, options *terraform.Options, name string) string {
	defer func() {
		options.Logger = nil
	}()
	options.Logger = logger.Discard
	return terraform.Output(t, options, name)
}

func checkRetinaPodsRunning(t *testing.T, clientset *kubernetes.Clientset) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	err := wait.PollUntilContextTimeout(ctx, 3*time.Second, 2*time.Minute, true, func(ctx context.Context) (bool, error) {
		pods, err := clientset.CoreV1().Pods("kube-system").List(ctx, metav1.ListOptions{
			LabelSelector: "k8s-app=retina",
		})
		if err != nil {
			return false, err
		}
		for _, pod := range pods.Items {
			if pod.Status.Phase != v1.PodRunning {
				return false, nil
			}
		}
		return true, nil
	})
	if err != nil {
		t.Fatalf("Retina pods did not start in time: %v\n", err)
	}
}
