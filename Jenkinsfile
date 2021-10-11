def packageName = "cnrnrf.deb"
def NF_CLONE_DIRECTORY="nf"
def YAML_CLONE_DIRECTORY="yaml"

pipeline {
    //agent any
    
    agent {
       dockerfile {
           filename 'Dockerfile'
           dir '.'
           args '--privileged --user=root --add-host bitbucket.ulakhaberlesme.com.tr:192.168.10.14 -v /var/run/docker.sock:/var/run/docker.sock '
           // label 'docker-cinardev'
        //    customWorkspace "${env.JOB_NAME}"
       }
    }
    

    // agent {
    //     docker { image 'cinar/cndev:bash' }
    //     // docker { image 'jenkins-lts-jdk11' }
    // }
    
    // https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/~cem.topkaya/cinar_amf.git
    // https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/~cem.topkaya/cinar_nrf.git
    // https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/cin/yaml.git
    
    parameters { 
        booleanParam(name: 'CLEAN_WORKSPACE', defaultValue: false, description: 'Clear Workspace') 
        string(name: 'NF_REPO_URL', defaultValue: 'https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/~cem.topkaya/cinar_amf.git', description: 'NF Repo adresi') 
        // string(name: 'NF_REPO_URL', defaultValue: 'ssh://git@bitbucket.ulakhaberlesme.com.tr:7999/~cem.topkaya/cinar_amf.git', description: 'NF Repo adresi') 
        string(name: 'NF_BRANCH_NAME', defaultValue: 'nokia', description: 'NF Brans adi') 
        string(name: 'NF_REPO_CRED_ID', defaultValue: 'bitbucket_cem.topkaya', description: 'NF Repo credential id') 
        string(name: 'YAML_REPO_URL', defaultValue: 'https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/cin/yaml.git', description: 'YAML Repo adresi') 
        // string(name: 'YAML_REPO_URL', defaultValue: 'ssh://git@bitbucket.ulakhaberlesme.com.tr:7999/cin/yaml.git', description: 'YAML Repo adresi') 
        string(name: 'YAML_BRANCH_NAME', defaultValue: 'master', description: 'YAML Brans adi')
        string(name: 'YAML_REPO_CRED_ID', defaultValue: 'bitbucket_cem.topkaya', description: 'YAML Repo credential id') 
        booleanParam(name: 'BUILD_NF', defaultValue: true, description: 'Starts to build')
        booleanParam(name: 'UPLOAD_DEBIAN_PACKAGE_TO_REPOSITORY', defaultValue: false, description: 'Upload debain package to repository') 
        string(name: 'DEBIAN_REPOSITORY_URL', defaultValue: 'http://192.168.13.173:8080/repos/latest', description: 'Repository address')
        booleanParam(name: 'CREATE_DOCKER_IMAGE', defaultValue: false, description: 'Create docker image from debian package')
        string(name: 'DOCKER_IMAGE_TAG', defaultValue: "amf:1", description: 'Docker image tag name')
    }
    
    
    stages {
        
        stage('Clean Workspace') {
            when{ 
                expression {params.CLEAN_WORKSPACE}
            }
            steps {
                script {
                    print "--->>>Workspace will be cleaned"
                    cleanWs()
                }
            }
        }


        stage('Clone Repos') {
            steps{
                script {
            ws("${env.JOB_NAME}") {
                    echo "params.YAML_BRANCH_NAME: ${params.YAML_BRANCH_NAME}"
                    echo "params.NF_BRANCH_NAME.isEmpty(): ${params.NF_BRANCH_NAME.isEmpty()}"
                    
                    if(params.YAML_BRANCH_NAME != null && !params.YAML_BRANCH_NAME.isEmpty()){
                        dir("${YAML_CLONE_DIRECTORY}") {
                            git branch: "${params.YAML_BRANCH_NAME}", credentialsId: "${NF_REPO_CRED_ID}", url: "${params.YAML_REPO_URL}"
                        }
                    }
                    
                    if(params.NF_BRANCH_NAME != null && !params.NF_BRANCH_NAME.isEmpty()){
                        dir("${NF_CLONE_DIRECTORY}") {
                            git branch: "${params.NF_BRANCH_NAME}", credentialsId: "${YAML_REPO_CRED_ID}", url: "${params.NF_REPO_URL}"
                        }
                    }
            }
                }
               
            }
        }
        
        stage('Building project'){
            when {
                expression { params.BUILD_NF }
            }
            steps{
                sh '''
                    export CINAR_BASE=/opt/cinar
                    export CINAR_CODE_GENERATOR_DIR=$CINAR_BASE/bin/ccg
                    echo "YAML_CLONE_DIRECTORY: ''' + YAML_CLONE_DIRECTORY + '''"
                    export CINAR_YAML_DIR=${WORKSPACE}/''' + YAML_CLONE_DIRECTORY + '''
                    echo "CINAR_YAML_DIR: $CINAR_YAML_DIR"
                    cd ${WORKSPACE}/''' + NF_CLONE_DIRECTORY + '''
                    pwd
                    ls -al
                    ls -Rl /etc/apt
                    cat /etc/apt/sources.list
                    cat /etc/apt/sources.list.d/cinar.list
                    make dist_fast
                '''
                    // make dist release=on
            }
        }
        
        stage('Uploading debian package'){
            when {
                expression { params.UPLOAD_DEBIAN_PACKAGE_TO_REPOSITORY }
            }
            steps{
                dir("${NF_CLONE_DIRECTORY}") {
                    sh 'echo "<<<< Building debian package named with ${packageName} >>>>>"'
                    //sh 'dpkg-deb --build ./dist ${packageName}'
                }
            }
        }
        
        stage('Dockerization'){
            when {
                expression { params.CREATE_DOCKER_IMAGE }
            }
            steps{
                sh 'echo "<<<< Building docker image >>>>>"'
                sh 'docker build -t 192.68.13.33:5000/cnrf:latest -f Dcokerfile .'
                
                sh 'echo "<<<< Publishing docker image >>>>>"'
                sh 'docker push 192.68.13.33:5000/cnrf:latest'
            }
        }
        
        stage('Mailing'){
            steps{
                sh 'echo "<<<< Mailing the results >>>>>"'
            }
        }
    }

}
