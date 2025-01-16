#!/bin/bash
# https://ev2docs.azure.net/features/service-artifacts/actions/shell-extensions/overview.html#script-authoring-and-packaging
# https://msazure.visualstudio.com/Azure-Express/_git/Samples?path=%2FServiceGroupRoot&version=GBmaster
# Debugging information
echo "Current directory: $(pwd)"
ls -l
# Check if Shell directory exists
if [ ! -d "./Shell" ]; then
    echo "Error: Shell directory does not exist."
    exit 1
fi

# package the script for ev2 shell extension
tar -C ./Shell -cvf Run.tar .

# write the ev2 version file
echo -n $BUILD_BUILDNUMBER | tee ./EV2Specs/BuildVer.txt


#new start
ARCHS=("Amd64" "Arm64")
for arch in "${ARCHS[@]}"; do
    mkdir $arch
done
echo "Current directory: $(pwd)"
ls -l
# IMAGE_NAMES=("agentInit" "agent" "operator")
IMAGE_NAMES=("agent")
#这个文件夹的名字应该取决于你如何name的pipeline，应该不是UI上的是yaml里的
for image in "${IMAGE_NAMES[@]}"; do
    ORIGINAL_DIRECTORY="../../../../retina-oss-build/drop_build_${image}Linux${arch}ImageBuild"
done
# for file in "$ORIGINAL_DIRECTORY"/*; do
#     if [[ "$file" == *.tar.gz ]]; then
#         gunzip $file
#         file="${file%.gz}"
#         BASENAME=$(basename $file)
#         NEW_NAME="${BASENAME%%-$BUILD_BUILDNUMBER*}.tar"
#         mv $file ./$arch/$NEW_NAME
#     fi
# done

for file in "$ORIGINAL_DIRECTORY"/*; do
    if [[ "$file" == *.tar.gz ]]; then
        gunzip "$file"  # 解压缩
        file="${file%.gz}"  # 去掉 .gz 后缀
        mv "$file" "./$arch/"  # 直接移动到新目录
    fi
done


#package all the pipeline output image to a tar file
mkdir multi_arch_image
# mv ../../../Retina-OSS-CG-Pipelines/output/images/linux/Amd64/* ./multi_arch_image/
# mv ../../../Retina-OSS-CG-Pipelines/output/images/linux/Arm64/* ./multi_arch_image/
echo "Current directory: $(pwd)"
ls -l

echo "Contents of Amd64 folder before moving:"
ls -l ./Amd64/
# 将 Amd64 文件夹中的内容移动到 multi_arch_image 目录
mv ./Amd64/* ./multi_arch_image/
echo "Contents of Arm64 folder before moving:"
ls -l ./Arm64/
# 将 Arm64 文件夹中的内容移动到 multi_arch_image 目录
mv ./Arm64/* ./multi_arch_image/

# package the folder output to tar since the rollout parameter only accept a specifc file
tar -cvf multi_arch_image.tar ./multi_arch_image
