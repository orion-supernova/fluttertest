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
        
        // Flutter path
        PATH = "/Users/muratcankoc/development/flutter/bin:${env.PATH}"
    }

    stages {
        stage('Verify Environment') {
            steps {
                sh '''
                    echo "PATH = $PATH"
                    which flutter
                    flutter --version
                '''
            }
        }

        stage('Checkout') {
            steps {
                git url: '/Users/muratcankoc/Desktop/fluttertest', branch: 'main'
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    flutter clean
                    flutter pub get
                    flutter build ios --release --no-codesign
                '''
            }
        }
        
        stage('iOS Build & Deploy') {
            steps {
                dir('ios') {
                    sh '''
                        xcodebuild -workspace Runner.xcworkspace \
                            -scheme Runner \
                            -configuration Release \
                            -archivePath Runner.xcarchive \
                            clean archive \
                            CODE_SIGN_IDENTITY="iPhone Distribution" \
                            DEVELOPMENT_TEAM="$DEVELOPER_PORTAL_TEAM_ID"
                            
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
        success {
            echo 'Successfully built and deployed to App Store!'
        }
        failure {
            echo 'Build or deployment failed!'
        }
    }
} 