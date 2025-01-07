pipeline {
    agent any
    
    options {
        skipDefaultCheckout(true) // Skip the default checkout
    }
    
    environment {
        // Apple Developer details
        DEVELOPER_PORTAL_TEAM_ID = '37TC2VKVJ6'
        DEVELOPER_APP_IDENTIFIER = 'com.walhallaa.spyFallFlutter'
        
        // App Store Connect API details
        ASC_KEY_ID = 'HY4C8ZCTXZ'
        ASC_ISSUER_ID = '33ee1d05-040f-46ad-ae55-8cea58f58e0a'
        ASC_KEY_PATH = '/Users/muratcankoc/Desktop/AppStoreConnectAPIKey'
    }

    stages {
        stage('Prepare Environment') {
            steps {
                node {
                    cleanWs() // Clean workspace before starting
                    script {
                        env.FLUTTER_ROOT = '/Users/muratcankoc/development/flutter'
                        env.PATH = "${env.FLUTTER_ROOT}/bin:${env.PATH}"
                        
                        // Verify environment
                        sh '''
                            echo "Workspace: ${WORKSPACE}"
                            echo "PATH: ${PATH}"
                            echo "Flutter location:"
                            ls -la ${FLUTTER_ROOT}/bin/flutter
                        '''
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                dir("${env.WORKSPACE}") {
                    // Clone the existing repository
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        extensions: [
                            [$class: 'CleanBeforeCheckout'],
                            [$class: 'CloneOption', depth: 1, noTags: true, reference: '', shallow: true]
                        ],
                        userRemoteConfigs: [[
                            url: '/Users/muratcankoc/Desktop/fluttertest'
                        ]]
                    ])
                }
            }
        }
        
        stage('Flutter Setup') {
            steps {
                sh '''
                    ${FLUTTER_ROOT}/bin/flutter doctor
                    ${FLUTTER_ROOT}/bin/flutter --version
                '''
            }
        }
        
        stage('Flutter Build') {
            steps {
                dir("${env.WORKSPACE}") {
                    sh '''
                        ${FLUTTER_ROOT}/bin/flutter clean
                        ${FLUTTER_ROOT}/bin/flutter pub get
                        ${FLUTTER_ROOT}/bin/flutter build ios --release --no-codesign
                    '''
                }
            }
        }
        
        stage('iOS Build') {
            steps {
                dir("${env.WORKSPACE}/ios") {
                    sh '''
                        xcodebuild -workspace Runner.xcworkspace \
                            -scheme Runner \
                            -configuration Release \
                            -archivePath Runner.xcarchive \
                            clean archive \
                            CODE_SIGN_IDENTITY="iPhone Distribution" \
                            DEVELOPMENT_TEAM="$DEVELOPER_PORTAL_TEAM_ID"
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                dir("${env.WORKSPACE}/ios") {
                    sh '''
                        xcodebuild -exportArchive \
                            -archivePath Runner.xcarchive \
                            -exportPath ./build \
                            -exportOptionsPlist <(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$DEVELOPER_PORTAL_TEAM_ID</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$DEVELOPER_APP_IDENTIFIER</key>
        <string>$DEVELOPER_APP_IDENTIFIER</string>
    </dict>
</dict>
</plist>
EOF
)
                        
                        xcrun altool --upload-app \
                            --type ios \
                            --file "build/Runner.ipa" \
                            --apiKey "$ASC_KEY_ID" \
                            --apiIssuer "$ASC_ISSUER_ID" \
                            --asc-provider "$DEVELOPER_PORTAL_TEAM_ID"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            node {
                script {
                    cleanWs(cleanWhenNotBuilt: false,
                           deleteDirs: true,
                           disableDeferredWipeout: true,
                           notFailBuild: true)
                }
            }
        }
        success {
            node {
                echo 'Successfully built and deployed to App Store!'
            }
        }
        failure {
            node {
                echo 'Build or deployment failed!'
            }
        }
    }
} 