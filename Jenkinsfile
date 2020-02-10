pipeline {
  agent {
    label 'X86-64-MULTI'
  }
  // Input to determine if this is a package check
  parameters {
      string(defaultValue: 'false', description: 'package check run', name: 'PACKAGE_CHECK')
  }
  // Configuration for the variables used for this specific repo
  environment {
    BUILDS_DISCORD=credentials('build_webhook_url')
    GITHUB_TOKEN=credentials('498b4638-2d04-4ce5-832d-8a57d01d97ac')
    JSON_URL = 'https://api.github.com/repos/cdr/code-server/releases'
    JSON_GITHUB_TAGNAME_PATH = 'first(.[] | select(.prerelease == false)) | .tag_name'
    JSON_GITHUB_NAME_PATH = 'first(.[] | select(.prerelease == false)) | .name'
    CONTAINER_NAME = 'code-server'
    LS_USER = 'gustavo8000br'
    LS_REPO = 'docker-code-server'
    DOCKERHUB_IMAGE = 'gustavo8000br/code-server'
    DEV_DOCKERHUB_IMAGE = 'gustavo8000br/code-server-dev'
    PR_DOCKERHUB_IMAGE = 'gustavo8000br/code-server-pr'
    DIST_IMAGE = 'ubuntu'
    MULTIARCH='true'
  }
  stages {
    // Setup all the basic environment variables needed for the build
    stage("Set ENV Variables base"){
      steps{
        script{
          env.EXIT_STATUS = ''
          env.LS_RELEASE = sh(
            script: '''docker run --rm alexeiled/skopeo sh -c 'skopeo inspect docker://docker.io/'${DOCKERHUB_IMAGE}':latest 2>/dev/null' | jq -r '.Labels.build_version' | awk '{print $3}' | grep '\\-ls' || : ''',
            returnStdout: true).trim()
          env.LS_RELEASE_NOTES = sh(
            script: '''cat readme-vars.yml | awk -F \\" '/date: "[0-9][0-9].[0-9][0-9].[0-9][0-9]:/ {print $4;exit;}' | sed -E ':a;N;$!ba;s/\\r{0,1}\\n/\\\\n/g' ''',
            returnStdout: true).trim()
          env.GITHUB_DATE = sh(
            script: '''date '+%Y-%m-%dT%H:%M:%S%:z' ''',
            returnStdout: true).trim()
          env.COMMIT_SHA = sh(
            script: '''git rev-parse HEAD''',
            returnStdout: true).trim()
          env.CODE_URL = 'https://github.com/' + env.LS_USER + '/' + env.LS_REPO + '/commit/' + env.GIT_COMMIT
          env.DOCKERHUB_LINK = 'https://hub.docker.com/r/' + env.DOCKERHUB_IMAGE + '/tags/'
          env.PULL_REQUEST = env.CHANGE_ID
          env.TEMPLATED_FILES = 'Jenkinsfile README.md LICENSE ./.github/FUNDING.yml ./.github/ISSUE_TEMPLATE.md ./.github/PULL_REQUEST_TEMPLATE.md'
        }
        script{
          env.LS_RELEASE_NUMBER = sh(
            script: '''echo ${LS_RELEASE} |sed 's/^.*-ls//g' ''',
            returnStdout: true).trim()
        }
        script{
          env.LS_TAG_NUMBER = sh(
            script: '''#! /bin/bash
                        tagsha=$(git rev-list -n 1 ${LS_RELEASE} 2>/dev/null)
                        if [ "${tagsha}" == "${COMMIT_SHA}" ]; then
                          echo ${LS_RELEASE_NUMBER}
                        elif [ -z "${GIT_COMMIT}" ]; then
                          echo ${LS_RELEASE_NUMBER}
                        else
                          echo $((${LS_RELEASE_NUMBER} + 1))
                        fi''',
            returnStdout: true).trim()
        }
      }
    }
    /* #######################
      Package Version Tagging
       ####################### */
    // Grab the current package versions in Git to determine package tag
    stage("Set Package tag"){
      steps{
        script{
          env.PACKAGE_TAG = sh(
            script: '''#!/bin/bash
                        if [ -e package_versions.txt ] ; then
                          cat package_versions.txt | md5 | cut -c1-8
                        else
                          echo none
                        fi''',
            returnStdout: true).trim()
        }
      }
    }
    /* #########################
      External Release Tagging
       ######################### */
    // If this is a custom json endpoint parse the return to get external tag
    stage("Set ENV GITHUB_TAGNAME"){
      steps{
        script{
          env.EXT_RELEASE_TAGNAME = sh(
            script: '''curl -s ${JSON_URL} | jq -r ". | ${JSON_GITHUB_TAGNAME_PATH}" ''',
            returnStdout: true).trim()
          env.RELEASE_LINK = env.JSON_URL
        }
      }
    }
    /* ########################
      External Release Name
       ######################## */
    // If this is a custom json endpoint parse the return to get external tag
    stage("Set ENV GITHUB_NAME"){
      steps{
        script{
          env.EXT_RELEASE_NAME = sh(
            script: '''curl -s ${JSON_URL} | jq -r ". | ${JSON_GITHUB_NAME_PATH}" ''',
            returnStdout: true).trim()
          env.RELEASE_LINK = env.JSON_URL
        }
      }
    }
    // Sanitize the release tagname and strip illegal docker or github characters
    stage("Sanitize GITHUB_TAGNAME"){
      steps{
        script{
          env.EXT_RELEASE_TAGNAME_CLEAN = sh(
            script: '''echo ${EXT_RELEASE_TAGNAME} | sed 's/[~,%@+;:/]//g' ''',
            returnStdout: true).trim()
        }
      }
    }
    // Sanitize the release name and strip illegal docker or github characters
    stage("Sanitize GITHUB_NAME"){
      steps{
        script{
          env.EXT_RELEASE_NAME_CLEAN = sh(
            script: '''echo ${EXT_RELEASE_NAME} | sed 's/[~,%@+;:/]//g' ''',
            returnStdout: true).trim()
        }
      }
    }
    // If this is a master build use live docker endpoints
    stage("Set ENV live build"){
      when {
        branch "master"
        environment name: 'CHANGE_ID', value: ''
      }
      steps {
        script{
          env.IMAGE = env.DOCKERHUB_IMAGE
          env.GITHUBIMAGE = 'docker.pkg.github.com/' + env.LS_USER + '/' + env.LS_REPO + '/' + env.CONTAINER_NAME
          env.META_TAG = env.EXT_RELEASE_TAGNAME_CLEAN + '-ls' + env.LS_TAG_NUMBER
        }
      }
    }
    // If this is a dev build use dev docker endpoints
    stage("Set ENV dev build"){
      when {
        not {branch "master"}
        environment name: 'CHANGE_ID', value: ''
      }
      steps {
        script{
          env.IMAGE = env.DEV_DOCKERHUB_IMAGE
          env.GITHUBIMAGE = 'docker.pkg.github.com/' + env.LS_USER + '/' + env.LS_REPO + '/gustavo8000br-' + env.CONTAINER_NAME
          env.META_TAG = env.EXT_RELEASE_TAGNAME_CLEAN + '-pkg-' + env.PACKAGE_TAG + '-dev-' + env.COMMIT_SHA
          env.DOCKERHUB_LINK = 'https://hub.docker.com/r/' + env.DEV_DOCKERHUB_IMAGE + '/tags/'
        }
      }
    }
    // If this is a pull request build use dev docker endpoints
    stage("Set ENV PR build"){
      when {
        not {environment name: 'CHANGE_ID', value: ''}
      }
      steps {
        script{
          env.IMAGE = env.PR_DOCKERHUB_IMAGE
          env.GITHUBIMAGE = 'docker.pkg.github.com/' + env.LS_USER + '/' + env.LS_REPO + '/gustavo8000br-' + env.CONTAINER_NAME
          env.META_TAG = env.EXT_RELEASE_TAGNAME_CLEAN + '-pkg-' + env.PACKAGE_TAG + '-pr-' + env.PULL_REQUEST
          env.CODE_URL = 'https://github.com/' + env.LS_USER + '/' + env.LS_REPO + '/pull/' + env.PULL_REQUEST
          env.DOCKERHUB_LINK = 'https://hub.docker.com/r/' + env.PR_DOCKERHUB_IMAGE + '/tags/'
        }
      }
    }
    /* ###############
      Build Container
       ############### */
    // Build Docker container for push to LS Repo
    stage('Build-Single') {
      when {
        environment name: 'MULTIARCH', value: 'false'
        environment name: 'EXIT_STATUS', value: ''
      }
      steps {
        sh "docker build --no-cache --pull -t ${IMAGE}:${META_TAG} \
        --build-arg VERSION=\"${META_TAG}\" --build-arg GITHUB_TAGNAME=${EXT_RELEASE_TAGNAME} --build-arg GITHUB_NAME=${EXT_RELEASE_NAME} --build-arg BUILD_DATE=${GITHUB_DATE} ."
      }
    }
    // Build MultiArch Docker containers for push to LS Repo
    stage('Build-Multi') {
      when {
        environment name: 'MULTIARCH', value: 'true'
        environment name: 'EXIT_STATUS', value: ''
      }
      parallel {
        stage('Build X86') {
          steps {
            sh "docker build --no-cache --pull -t ${IMAGE}:amd64-${META_TAG} \
            --build-arg VERSION=\"${META_TAG}\" --build-arg GITHUB_TAGNAME=${EXT_RELEASE_TAGNAME} --build-arg GITHUB_NAME=${EXT_RELEASE_NAME} --build-arg BUILD_DATE=${GITHUB_DATE} ."
          }
        }
        stage('Build ARM64') {
          agent {
            label 'ARM64'
          }
          steps {
            withCredentials([
              [
                $class: 'UsernamePasswordMultiBinding',
                credentialsId: '3f9ba4d5-100d-45b0-a3c4-633fd6061207',
                usernameVariable: 'DOCKERUSER',
                passwordVariable: 'DOCKERPASS'
              ]
            ]) {
              echo 'Logging into DockerHub'
              sh '''#! /bin/bash
                  echo $DOCKERPASS | docker login -u $DOCKERUSER --password-stdin
                  '''
              sh "docker build --no-cache --pull -f Dockerfile.aarch64 -t ${IMAGE}:arm64v8-${META_TAG} \
                            --build-arg VERSION=\"${META_TAG}\" --build-arg GITHUB_TAGNAME=${EXT_RELEASE_TAGNAME} --build-arg GITHUB_NAME=${EXT_RELEASE_NAME} --build-arg BUILD_DATE=${GITHUB_DATE} ."
            }
          }
        }
      }
    }
    // Take the image we just built and dump package versions for comparison
    stage('Update-packages') {
      when {
        branch "master"
        environment name: 'CHANGE_ID', value: ''
        environment name: 'EXIT_STATUS', value: ''
      }
      steps {
        sh '''#! /bin/bash
              set -e
              TEMPDIR=$(mktemp -d)
              if [ "${MULTIARCH}" == "true" ]; then
                LOCAL_CONTAINER=${IMAGE}:amd64-${META_TAG}
              else
                LOCAL_CONTAINER=${IMAGE}:${META_TAG}
              fi
              if [ "${DIST_IMAGE}" == "alpine" ]; then
                docker run --rm --entrypoint '/bin/sh' -v ${TEMPDIR}:/tmp ${LOCAL_CONTAINER} -c '\
                  apk info -v > /tmp/package_versions.txt && \
                  sort -o /tmp/package_versions.txt  /tmp/package_versions.txt && \
                  chmod 777 /tmp/package_versions.txt'
              elif [ "${DIST_IMAGE}" == "ubuntu" ]; then
                docker run --rm --entrypoint '/bin/sh' -v ${TEMPDIR}:/tmp ${LOCAL_CONTAINER} -c '\
                  apt list -qq --installed | sed "s#/.*now ##g" | cut -d" " -f1 > /tmp/package_versions.txt && \
                  sort -o /tmp/package_versions.txt  /tmp/package_versions.txt && \
                  chmod 777 /tmp/package_versions.txt'
              fi
              NEW_PACKAGE_TAG=$(md5 ${TEMPDIR}/package_versions.txt | cut -c1-8 )
              echo "Package tag sha from current packages in buit container is ${NEW_PACKAGE_TAG} comparing to old ${PACKAGE_TAG} from github"
              if [ "${NEW_PACKAGE_TAG}" != "${PACKAGE_TAG}" ]; then
                git clone https://github.com/${LS_USER}/${LS_REPO}.git ${TEMPDIR}/${LS_REPO}
                git --git-dir ${TEMPDIR}/${LS_REPO}/.git checkout -f master
                cp ${TEMPDIR}/package_versions.txt ${TEMPDIR}/${LS_REPO}/
                cd ${TEMPDIR}/${LS_REPO}/
                wait
                git add package_versions.txt
                git commit -m 'Bot Updating Package Versions'
                git push https://gustavo8000br:${GITHUB_TOKEN}@github.com/${LS_USER}/${LS_REPO}.git --all
                echo "true" > /tmp/packages-${COMMIT_SHA}-${BUILD_NUMBER}
                echo "Package tag updated, stopping build process"
              else
                echo "false" > /tmp/packages-${COMMIT_SHA}-${BUILD_NUMBER}
                echo "Package tag is same as previous continue with build process"
              fi
              rm -Rf ${TEMPDIR}'''
        script{
          env.PACKAGE_UPDATED = sh(
            script: '''cat /tmp/packages-${COMMIT_SHA}-${BUILD_NUMBER}''',
            returnStdout: true).trim()
        }
      }
    }
    // Exit the build if the package file was just updated
    stage('PACKAGE-exit') {
      when {
        branch "master"
        environment name: 'CHANGE_ID', value: ''
        environment name: 'PACKAGE_UPDATED', value: 'true'
        environment name: 'EXIT_STATUS', value: ''
      }
      steps {
        script{
          env.EXIT_STATUS = 'ABORTED'
        }
      }
    }
    // Exit the build if this is just a package check and there are no changes to push
    stage('PACKAGECHECK-exit') {
      when {
        branch "master"
        environment name: 'CHANGE_ID', value: ''
        environment name: 'PACKAGE_UPDATED', value: 'false'
        environment name: 'EXIT_STATUS', value: ''
        expression {
          params.PACKAGE_CHECK == 'true'
        }
      }
      steps {
        script{
          env.EXIT_STATUS = 'ABORTED'
        }
      }
    }
    /* ##################
        Release Logic
       ################## */
    // If this is an amd64 only image only push a single image
    stage('Docker-Push-Single') {
      when {
        environment name: 'MULTIARCH', value: 'false'
        environment name: 'EXIT_STATUS', value: ''
      }
      steps {
        withCredentials([
          [
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: '3f9ba4d5-100d-45b0-a3c4-633fd6061207',
            usernameVariable: 'DOCKERUSER',
            passwordVariable: 'DOCKERPASS'
          ]
        ]) {
          sh '''#! /bin/bash
                set -e
                echo $DOCKERPASS | docker login -u $DOCKERUSER --password-stdin
                echo $GITHUB_TOKEN | docker login docker.pkg.github.com -u gustavo8000br --password-stdin
                for PUSHIMAGE in "${GITHUBIMAGE}" "${IMAGE}"; do
                  docker tag ${IMAGE}:${META_TAG} ${PUSHIMAGE}:${META_TAG}
                  docker tag ${PUSHIMAGE}:${META_TAG} ${PUSHIMAGE}:development
                  docker push ${PUSHIMAGE}:development
                  docker push ${PUSHIMAGE}:${META_TAG}
                done
                for DELETEIMAGE in "${GITHUBIMAGE}" "${IMAGE}"; do
                  docker rmi \
                  ${DELETEIMAGE}:${META_TAG} \
                  ${DELETEIMAGE}:development || :
                done
              '''
        }
      }
    }
    // If this is a multi arch release push all images and define the manifest
    stage('Docker-Push-Multi') {
      when {
        environment name: 'MULTIARCH', value: 'true'
        environment name: 'EXIT_STATUS', value: ''
      }
      steps {
        withCredentials([
          [
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: '3f9ba4d5-100d-45b0-a3c4-633fd6061207',
            usernameVariable: 'DOCKERUSER',
            passwordVariable: 'DOCKERPASS'
          ],
          [
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: 'Quay.io-Robot',
            usernameVariable: 'QUAYUSER',
            passwordVariable: 'QUAYPASS'
          ]
        ]) {
          sh '''#! /bin/bash
                set -e
                echo $DOCKERPASS | docker login -u $DOCKERUSER --password-stdin
                echo $GITHUB_TOKEN | docker login docker.pkg.github.com -u gustavo8000br --password-stdin
                for MANIFESTIMAGE in "${IMAGE}" "${GITHUBIMAGE}"; do
                  docker tag ${IMAGE}:amd64-${META_TAG} ${MANIFESTIMAGE}:amd64-${META_TAG}
                  docker tag ${IMAGE}:arm64v8-${META_TAG} ${MANIFESTIMAGE}:arm64v8-${META_TAG}
                  docker tag ${MANIFESTIMAGE}:amd64-${META_TAG} ${MANIFESTIMAGE}:amd64-development
                  docker tag ${MANIFESTIMAGE}:arm64v8-${META_TAG} ${MANIFESTIMAGE}:arm64v8-development
                  docker push ${MANIFESTIMAGE}:amd64-${META_TAG}
                  docker push ${MANIFESTIMAGE}:arm64v8-${META_TAG}
                  docker push ${MANIFESTIMAGE}:amd64-development
                  docker push ${MANIFESTIMAGE}:arm64v8-development
                  docker manifest push --purge ${MANIFESTIMAGE}:development || :
                  docker manifest annotate ${MANIFESTIMAGE}:development ${MANIFESTIMAGE}:arm64v8-development --os linux --arch arm64 --variant v8
                  docker manifest push --purge ${MANIFESTIMAGE}:${META_TAG} || :
                  docker manifest annotate ${MANIFESTIMAGE}:${META_TAG} ${MANIFESTIMAGE}:arm64v8-${META_TAG} --os linux --arch arm64 --variant v8
                  docker manifest push --purge ${MANIFESTIMAGE}:development
                  docker manifest push --purge ${MANIFESTIMAGE}:${META_TAG} 
                done
                for LEGACYIMAGE in "${GITHUBIMAGE}"; do
                  docker tag ${IMAGE}:amd64-${META_TAG} ${LEGACYIMAGE}:amd64-${META_TAG}
                  docker tag ${IMAGE}:arm64v8-${META_TAG} ${LEGACYIMAGE}:arm64v8-${META_TAG}
                  docker tag ${LEGACYIMAGE}:amd64-${META_TAG} ${LEGACYIMAGE}:development
                  docker tag ${LEGACYIMAGE}:amd64-${META_TAG} ${LEGACYIMAGE}:${META_TAG}
                  docker tag ${LEGACYIMAGE}:arm64v8-${META_TAG} ${LEGACYIMAGE}:arm64v8-development
                  docker push ${LEGACYIMAGE}:amd64-${META_TAG}
                  docker push ${LEGACYIMAGE}:arm64v8-${META_TAG}
                  docker push ${LEGACYIMAGE}:development
                  docker push ${LEGACYIMAGE}:${META_TAG}
                  docker push ${LEGACYIMAGE}:arm64v8-development 
                done
              '''
          sh '''#! /bin/bash
                for DELETEIMAGE in "${GITHUBIMAGE}" "${IMAGE}"; do
                  docker rmi \
                  ${DELETEIMAGE}:amd64-${META_TAG} \
                  ${DELETEIMAGE}:amd64-development \
                  ${DELETEIMAGE}:arm64v8-${META_TAG} \
                  ${DELETEIMAGE}:arm64v8-development || :
                done
              '''
        }
      }
    }
    // If this is a public release tag it in the LS Github
    stage('Github-Tag-Push-Release') {
      when {
        branch "master"
        expression {
          env.LS_RELEASE != env.EXT_RELEASE_TAGNAME_CLEAN + '-ls' + env.LS_TAG_NUMBER
        }
        environment name: 'CHANGE_ID', value: ''
        environment name: 'EXIT_STATUS', value: ''
      }
      steps {
        echo "Pushing New tag for current commit ${EXT_RELEASE_TAGNAME_CLEAN}-ls${LS_TAG_NUMBER}"
        sh '''curl -H "Authorization: token ${GITHUB_TOKEN}" -X POST https://api.github.com/repos/${LS_USER}/${LS_REPO}/git/tags \
        -d '{"tag":"'${EXT_RELEASE_TAGNAME_CLEAN}'-ls'${LS_TAG_NUMBER}'",\
              "object": "'${COMMIT_SHA}'",\
              "message": "Tagging Release '${EXT_RELEASE_TAGNAME_CLEAN}'-ls'${LS_TAG_NUMBER}' to master",\
              "type": "commit",\
              "tagger": {"name": "Gustavo8000br Jenkins","email": "gustavo.mathias.rocha@gmail.com","date": "'${GITHUB_DATE}'"}}' '''
        echo "Pushing New release for Tag"
        sh '''#! /bin/bash
              echo "Data change at JSON endpoint ${JSON_URL}" > releasebody.json
              echo '{"tag_name":"'${EXT_RELEASE_TAGNAME_CLEAN}'-ls'${LS_TAG_NUMBER}'",\
                      "target_commitish": "master",\
                      "name": "'${EXT_RELEASE_TAGNAME_CLEAN}'-ls'${LS_TAG_NUMBER}'",\
                      "body": "**Gustavo8000br Changes:**\\n\\n'${LS_RELEASE_NOTES}'\\n**Remote Changes:**\\n\\n' > start
              printf '","draft": false,"prerelease": true}' >> releasebody.json
              paste -d'\\0' start releasebody.json > releasebody.json.done
              curl -H "Authorization: token ${GITHUB_TOKEN}" -X POST https://api.github.com/repos/${LS_USER}/${LS_REPO}/releases -d @releasebody.json.done'''
      }
    }
  /* ######################
    Send status to Discord
     ###################### */
  post {
    always {
      script{
        if (env.EXIT_STATUS == "ABORTED"){
          sh 'echo "build aborted"'
        }
        else if (currentBuild.currentResult == "SUCCESS"){
          sh ''' curl -X POST -H "Content-Type: application/json" --data '{"avatar_url": "https://wiki.jenkins-ci.org/download/attachments/2916393/headshot.png","embeds": [{"color": 1681177,\
                  "description": "**Build:**  '${BUILD_NUMBER}'\\n**Status:**  Success\\n**Job:** '${RUN_DISPLAY_URL}'\\n**Change:** '${CODE_URL}'\\n**External Release:**: '${RELEASE_LINK}'\\n**DockerHub:** '${DOCKERHUB_LINK}'\\n"}],\
                  "username": "Jenkins"}' ${BUILDS_DISCORD} '''
        }
        else {
          sh ''' curl -X POST -H "Content-Type: application/json" --data '{"avatar_url": "https://wiki.jenkins-ci.org/download/attachments/2916393/headshot.png","embeds": [{"color": 16711680,\
                  "description": "**Build:**  '${BUILD_NUMBER}'\\n**Status:**  failure\\n**Job:** '${RUN_DISPLAY_URL}'\\n**Change:** '${CODE_URL}'\\n**External Release:**: '${RELEASE_LINK}'\\n**DockerHub:** '${DOCKERHUB_LINK}'\\n"}],\
                  "username": "Jenkins"}' ${BUILDS_DISCORD} '''
        }
      }
    }
    cleanup {
      cleanWs()
    }
  }
}
