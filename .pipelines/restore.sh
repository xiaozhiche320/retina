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
# ARCHS=("Amd64" "Arm64")
# for arch in "${ARCHS[@]}"; do
#     mkdir $arch
#     IMAGE_NAMES=("agentInit" "agent" "operator")
#     # IMAGE_NAMES=("agent")
#     #这个文件夹的名字应该取决于你如何name的pipeline，应该不是UI上的是yaml里的
#     for image in "${IMAGE_NAMES[@]}"; do
#         ORIGINAL_DIRECTORY="../../../../retina-oss-build/drop_build_${image}Linux${arch}ImageBuild"

#         for file in "$ORIGINAL_DIRECTORY"/*; do
#             if [[ "$file" == *.tar.gz ]]; then
#                 gunzip "$file"  # 解压缩
#                 file="${file%.gz}"  # 去掉 .gz 后缀
#                 mv "$file" "./$arch/"  # 直接移动到新目录
#             fi
#         done
#         echo "$arch Folder Contents"
#         ls -alF $arch
#     done
# done
echo "Listing contents of ../../../../"
ls ../../../../

for arch in "${ARCHS[@]}"; do
    mkdir -p "$arch"
    IMAGE_NAMES=("agentInit" "agent" "operator")

    for image in "${IMAGE_NAMES[@]}"; do
        ORIGINAL_DIRECTORY="../../../../retina-oss-build/drop_build_${image}Linux${arch}ImageBuild"
        
        # 检查目录是否存在
        if [ ! -d "$ORIGINAL_DIRECTORY" ]; then
            echo "Error: Directory does not exist - $ORIGINAL_DIRECTORY"
            continue
        fi
        
        echo "Processing directory: $ORIGINAL_DIRECTORY"
        ls -alF "$ORIGINAL_DIRECTORY"

        for file in "$ORIGINAL_DIRECTORY"/*; do
            echo "Processing file: $file"
            if [[ "$file" == *.tar.gz ]]; then
                echo "Decompressing file: $file"
                gunzip "$file" && echo "Decompressed: $file"
                file="${file%.gz}"
                if [ -f "$file" ]; then
                    echo "Moving file: $file to ./$arch/"
                    mv "$file" "./$arch/"
                else
                    echo "Error: File $file not found after decompression."
                fi
            else
                echo "Skipping non-matching file: $file"
            fi
        done

        echo "$arch Folder Contents:"
        ls -alF "$arch"
    done
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
