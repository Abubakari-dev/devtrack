@echo off
echo ========================================
echo Deploying Firestore Rules and Indexes
echo ========================================
echo.
echo This will deploy:
echo - Firestore security rules (root collections)
echo - Firestore indexes (userId + projectId + date)
echo.
pause
echo.
echo Deploying rules...
firebase deploy --only firestore:rules
echo.
echo Deploying indexes...
firebase deploy --only firestore:indexes
echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo IMPORTANT: 
echo 1. Wait 1-2 minutes for indexes to build
echo 2. Restart your app completely
echo 3. Test by adding a savings record
echo.
pause
