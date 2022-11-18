#!/usr/bin/env bash

# set -ex ;export PS4='+[$(TZ="Asia/Shanghai" date "+%Y-%m-%d %T.%3N")](${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

local_vs=versions.json

if [ ! -f "$local_vs" ]; then
    echo "no version file! "
    exit 1
fi

images=(
    $(cat $local_vs |jq  '.dockers |to_entries[] |.key +":"+ .value' )
)

error_images=()

push_images(){
    local ori_base=${ORI_BASE:-registry.cn-beijing.aliyuncs.com/yunionio}
    local new_base=${NEW_BASE:-registry.cn-beijing.aliyuncs.com/yunion}
    local image=$1  # host:v12.34
    local old_image=$ori_base/$image
    local new_image=$new_base/$image
    local max_wait=${MAX_TIMES:-3}
    local max_sleep=${MAX_SLEEP_SECS:-10}
    local args=()

    if docker manifest inspect ${new_image} &>/dev/null; then
        args=( --amend )
    fi

    for i in $(seq 1 1 $max_wait); do
        echo "try push image $image to $new_base @ $i/$max_wait"
        if  docker pull     ${old_image} --platform arm64 && \
            docker tag      ${old_image} ${new_image}-arm64 && \
            docker push     ${new_image}-arm64 && \
            docker pull     ${old_image} --platform amd64 && \
            docker tag      ${old_image} ${new_image}-amd64 && \
            docker push     ${new_image}-amd64 && \
            docker manifest create ${args[@]} ${new_image} ${new_image}-amd64 ${new_image}-arm64 && \
            docker manifest inspect ${new_image} &>/dev/null && \
            docker manifest push ${new_image}; then
            echo "[PASS] push image $image to $new_base OK. "
            return
        fi
        sleep ${MAX_SLEEP_SECS:-3}
    done
    echo "[ERROR] push image $image to $new_base failed. "
    error_images+=(
        $image
    )
}
index=0
echo ""
total=${#images[@]}
for img in ${images[@]}; do
    index=$((index + 1))
    echo "[${index}/${total}] processing $img ... "
    echo MAX_SLEEP_SECS=10 MAX_TIMES=3 NEW_BASE=yunion push_images $img
done

error_count=${#error_images[@]}
if [[ "$error_count" -gt 0 ]]; then
    echo "ERROR pushing images:"
    echo ${error_count[@]}
    exit 1
else
    echo "All done and all good."
fi
