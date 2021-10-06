def packageName = "cnrnrf.deb"


pipeline {
    //agent any
    
    agent {
        dockerfile {
            filename 'Dockerfile'
            dir '.'
            // label 'docker-cinardev'
        }
    }
    

    // agent {
    //     docker { image 'cinar/cndev:bash' }
    //     // docker { image 'jenkins-lts-jdk11' }
    // }
    
    // https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/~cem.topkaya/cinar_amf.git
    // https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/~cem.topkaya/cinar_nrf.git
    
    parameters { 
        booleanParam(name: 'CLEAN_WORKSPACE', defaultValue: false, description: 'Clear Workspace') 
        string(name: 'NF_REPO_URL', defaultValue: 'https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/~cem.topkaya/cinar_amf.git', description: 'NF Repo adresi') 
        string(name: 'NRF_BRANCH_NAME', defaultValue: 'NRF_CNF', description: 'NRF Brans adi') 
        string(name: 'YAML_REPO_URL', defaultValue: 'https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/cin/yaml.git', description: 'YAML Repo adresi') 
        string(name: 'YAML_BRANCH_NAME', defaultValue: 'master', description: 'YAML Brans adi')
        booleanParam(name: 'UPLOAD_DEBIAN_PACKAGE_TO_REPOSITORY', defaultValue: false, description: 'Upload debain package to repository') 
        string(name: 'DEBIAN_REPOSITORY_URL', defaultValue: 'http://192.168.13.173:8080/repos/latest', description: 'Repository address')
        booleanParam(name: 'CREATE_DOCKER_IMAGE', defaultValue: false, description: 'Create docker image from debian package')
        string(name: 'DOCKER_IMAGE_TAG', defaultValue: "amf:1", description: 'Docker image tag name')
    }
    
    
    stages {
        
        stage('Clean Workspace') {
            steps {
                script {
                    if(params.CLEAN_WORKSPACE){
                        print "--->>>Workspace will be cleaned"
                        cleanWs()
                    }
                }
            }
        }


        stage('Clone Repos') {
            steps {
                if($YAML_BRANCH_NAME!=""){
                    dir('yaml') {
                        git branch: "${YAML_BRANCH_NAME}", credentialsId: 'bb_cem.topkaya', url: '${YAML_REPO_URL}'
                    }
                }
                
                if($NRF_BRANCH_NAME!=""){
                    dir('nf') {
                        git branch: "${NRF_BRANCH_NAME}", credentialsId: 'bb_cem.topkaya', url: '${NF_REPO_URL}'
                    }
                }
            }
        }
        
        stage('Building project'){
            steps{
                sh '''
                    export CINAR_BASE=/opt/cinar
                    export CINAR_CODE_GENERATOR_DIR=$CINAR_BASE/bin/ccg
                    export CINAR_YAML_DIR=`pwd`/yaml
                    echo "CINAR_YAML_DIR: $CINAR_YAML_DIR"
                    cd nrf
                    make dist release=on
                '''
            }
        }
        
        stage('Building debian package'){
            steps{
                dir('nrf') {
                    sh 'echo "<<<< Building debian package named with ${packageName} >>>>>"'
                    sh 'dpkg-deb --build ./dist ${packageName}'
                }
            }
        }
        
        stage('Dockerization'){
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
