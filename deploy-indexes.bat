@echo off
echo ========================================
echo Deploying Firestore Indexes
echo ========================================
echo.
echo This will deploy the savings index to Firebase...
echo.
firebase deploy --only firestore:indexes
echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Please restart your app to see the changes.
echo.
pause
