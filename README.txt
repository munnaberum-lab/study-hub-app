Study Hub - Flutter native app (backend: aapki Render site ki /api/v1 API)

1) Pehle backend update karo: backend_patch ke 2 files (web/api.py, web/session.py)
   apne bot/website repo mein replace karo aur Render pe redeploy karo.
   (Isse login ka token aur /api/v1/videos/{id}/play endpoint milta hai.)
2) App ka link / naam: lib/api.dart ke upar kBaseUrl aur kAppName.
3) APK banana (phone se): is folder ke saare files (.github samet) naye GitHub repo mein upload karo,
   Actions -> Build APK -> Run workflow -> Artifacts se StudyHub-apk download karo.
   Ya laptop pe: flutter create --platforms=android . && flutter build apk --release
