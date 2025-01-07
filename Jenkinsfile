pipeline {
    agent any
    
    environment {
        // Apple Developer details
        DEVELOPER_PORTAL_TEAM_ID = '37TC2VKVJ6'
        DEVELOPER_APP_IDENTIFIER = 'com.walhallaa.spyFallFlutter'
        
        // App Store Connect API details
        ASC_KEY_ID = 'HY4C8ZCTXZ'
        ASC_ISSUER_ID = '33ee1d05-040f-46ad-ae55-8cea58f58e0a'
        ASC_KEY_PATH = '/Users/muratcankoc/Desktop/AppStoreConnectAPIKey'
        
        // Flutter path - using correct path from your system
        FLUTTER_HOME = '/Users/muratcankoc/development/flutter'
        PATH = "${FLUTTER_HOME}/bin:${env.PATH}"
    }

    triggers {
        // Poll SCM every 5 minutes for changes
        pollSCM('*/5 * * * *')
    }

    stages {
        stage('Setup') {
            steps {
                sh '''
                    echo "Current PATH: $PATH"
                    echo "Flutter location:"
                    which flutter || true
                    echo "Verifying Flutter installation..."
                    ${FLUTTER_HOME}/bin/flutter --version || (echo "Flutter not found in PATH" && exit 1)
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [],
                    userRemoteConfigs: [[
                        url: '/Users/muratcankoc/Desktop/fluttertest'
                    ]]
                ])
            }
        }
        
        stage('Flutter Clean') {
            steps {
                sh '''
                    ${FLUTTER_HOME}/bin/flutter clean
                    ${FLUTTER_HOME}/bin/flutter pub get
                '''
            }
        }
        
        stage('Build iOS') {
            steps {
                sh '''
                    ${FLUTTER_HOME}/bin/flutter build ios --release --no-codesign
                    cd ios
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
        
        stage('Deploy to App Store') {
            steps {
                sh '''
                    cd ios
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
    
    post {
        success {
            echo 'Successfully built and deployed to App Store!'
        }
        failure {
            echo 'Build or deployment failed!'
        }
    }
} 