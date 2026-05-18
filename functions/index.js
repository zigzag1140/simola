const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Fungsi ini akan terpicu otomatis setiap kali ESP32 menambah data ke collection "alerts"
exports.pantauKondisiDarurat = functions.firestore
    .document('alerts/{tanggal}')
    .onWrite(async (change, context) => {
        // Jika dokumen dihapus, abaikan
        if (!change.after.exists) return null;

        const dataSebelum = change.before.exists ? change.before.data() : {};
        const dataBaru = change.after.data();

        // Cari timestamp (key ts_...) yang baru saja masuk dari ESP32
        let tsTerbaru = null;
        for (const key in dataBaru) {
            // Jika ada key di data baru tapi tidak ada di data lama, itu data barunya
            if (!dataSebelum[key]) {
                tsTerbaru = key;
                break;
            }
        }

        // Jika tidak ada data baru (misalnya cuma update field lain), hentikan
        if (!tsTerbaru) return null;

        // Ambil isi data yang baru dikirim ESP32
        const alertData = dataBaru[tsTerbaru];

        // Ambil tipe alert (SOS atau BAHAYA)
        const tipeAlert = alertData.Tipe || "BAHAYA";

        // Siapkan "Rudal Notifikasi" (Payload)
        const payload = {
            data: {
                tipe: tipeAlert,
                title: tipeAlert === "SOS" ? "DARURAT SOS!" : "Peringatan Cuaca Laut",
                body: tipeAlert === "SOS" ? "Nelayan menekan tombol SOS. Segera cek lokasi!" : "Kondisi laut terpantau BAHAYA!",
            },
            topic: "semua_nelayan" // Dikirim ke semua HP yang menginstal aplikasi ini
        };

        // Tembakkan notifikasi ke HP
        try {
            await admin.messaging().send(payload);
            console.log(`Sukses mengirim notifikasi ${tipeAlert} ke HP!`);
        } catch (error) {
            console.error("Gagal mengirim notifikasi:", error);
        }

        return null;
    });