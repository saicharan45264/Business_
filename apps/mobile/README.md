# Giri Fruits Android app

This Android development preview connects to the existing API and Docker PostgreSQL database. It is not ready for live business records.

## Run on the Android emulator

1. Keep several GB of disk space free. The emulator refuses to start when storage is low.
2. Start Docker Desktop, then from the project root run:

   ```sh
   docker compose up -d
   npm run dev:api
   ```

3. In another terminal, review Android licenses when prompted:

   ```sh
   flutter doctor --android-licenses
   ```

4. Launch the emulator and wait for Android to finish starting:

   ```sh
   flutter emulators --launch Medium_Phone_API_36.1
   flutter devices
   ```

5. Run the app:

   ```sh
   cd apps/mobile
   flutter pub get
   flutter run -d emulator-5554
   ```

   Use the emulator ID shown by `flutter devices` if it differs.

The emulator uses `http://10.0.2.2:3000/api/v1`. For a USB-connected Android phone, enable USB debugging, run `adb reverse tcp:3000 tcp:3000`, then use `flutter run --dart-define=API_URL=http://127.0.0.1:3000/api/v1`.

The server has no authentication or HTTPS. Do not expose it to a network or use this preview for real business records. Android cleartext is enabled for local development. Production needs authentication, HTTPS, secure credentials, backups, and device verification.

The initial app does not yet include search, date filters, bill editing, PDF or WhatsApp sharing, offline access, previous-due preview, or invoice payment allocation. Check the bill list before retrying if a save response is lost.
