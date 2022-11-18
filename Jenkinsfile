pipeline {
    agent { node { label "office" } }
    options {
        ansiColor('xterm')
        retry(3)
    }
    stages {
        stage("action") {
            steps{
                git branch: 'main', url: 'https://github.com/yunion-ci-robot/sync-images.git'

            sh '''
                if [[ "$debug_level" -eq 1 ]]; then
                    set -x;
                elif [[ "$debug_level" -eq 2 ]]; then
                    set -x ;export PS4='+[$(TZ="Asia/Shanghai" date "+%F %T.%3N")](${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
                fi

                local_vs=$(mktemp).json
                rsync -Pva $version_file versions.json
                tag=$(cat $local_vs |jq .version |tr -d '"' |sed -e 's#[^/]*/##g')
                echo tag $tag
                '''
            }
        }
    }
}

// ft=groovy
