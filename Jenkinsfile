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
    
    parameters { 
        string(name: 'YAML_BRANCH_NAME', defaultValue: 'master', description: 'YAML Brans adi')
        string(name: 'NRF_BRANCH_NAME', defaultValue: 'NRF_CNF', description: 'NRF Brans adi') 
    }
    
    
    stages {
        
        stage('Install required packages') {
            steps {
                cleanWs()
                // export CINAR_YAML_DIR=/home/jenkins/workspace/${JOB_NAME}/yaml
                sh 'echo "<<<< paket kurulumu >>>>>"'
                //sh 'apt-get install -y cnrnrf=1.0.0.687.debug'
            }
        }

        stage('Build') {
            steps {
                dir('yaml') {
                    git branch: "${YAML_BRANCH_NAME}", credentialsId: 'bb_cem.topkaya', url: 'https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/cin/yaml.git'
                }
                
                dir('nrf') {
                    git branch: "${NRF_BRANCH_NAME}", credentialsId: 'bb_cem.topkaya', url: 'https://cem.topkaya@bitbucket.ulakhaberlesme.com.tr:8443/scm/cin/cinar_nrf.git'
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
