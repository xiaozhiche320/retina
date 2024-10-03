// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

package telemetry

import (
	"context"
	"os/exec"
	"strings"

	"github.com/pkg/errors"
)

func KernelVersion(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, ".\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", "$([Environment]::OSVersion).VersionString")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", errors.Wrapf(err, "failed to get windows kernel version: %s", string(output))
	}
	println("heartbeat windows kernel version from underlying: ", strings.TrimSuffix(string(output), "\r\n"))
	return strings.TrimSuffix(string(output), "\r\n"), nil
}
