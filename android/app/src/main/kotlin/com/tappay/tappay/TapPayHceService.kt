package com.tappay.tappay

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Host Card Emulation service that makes this phone behave as an NFC Forum Type 4 Tag.
 *
 * The merchant app sets an NDEF text payload (the signed payment-session URI) via
 * [setNdefText]; any standard NFC reader — including the TapPay customer app — that taps
 * this phone reads it exactly like a physical NFC tag. This is what turns "write to a tag"
 * into true phone-to-phone tap payments.
 *
 * Implements the NDEF Tag Application (AID D2760000850101) with the Capability Container
 * file (E103) and NDEF file (E104), per the NFC Forum Type 4 Tag Operation spec.
 */
class TapPayHceService : HostApduService() {

    companion object {
        private val OK = byteArrayOf(0x90.toByte(), 0x00)
        private val FILE_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        private val ERROR = byteArrayOf(0x6D.toByte(), 0x00)

        private val NDEF_AID = byteArrayOf(
            0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01,
        )

        // Capability Container: v2.0 mapping, MLe/MLc 0x7F, NDEF file E104 (max 0x7FFF,
        // read allowed 0x00, write forbidden 0xFF — the payload is server-signed anyway).
        private val CC_FILE = byteArrayOf(
            0x00, 0x0F, 0x20, 0x00, 0x7F, 0x00, 0x7F,
            0x04, 0x06, 0xE1.toByte(), 0x04, 0x7F, 0xFF.toByte(), 0x00, 0xFF.toByte(),
        )

        private const val FILE_NONE = 0
        private const val FILE_CC = 1
        private const val FILE_NDEF = 2

        /** NDEF file contents (2-byte NLEN prefix + NDEF message). Null = nothing to serve. */
        @Volatile
        private var ndefFile: ByteArray? = null

        /** Sets the broadcast payload as a single NDEF text record (matches the tag format the app already reads). */
        fun setNdefText(text: String) {
            val lang = "en".toByteArray(Charsets.US_ASCII)
            val textBytes = text.toByteArray(Charsets.UTF_8)
            val payload = byteArrayOf(lang.size.toByte()) + lang + textBytes
            // Short record: MB|ME|SR|TNF=well-known (0xD1), type length 1, type 'T'.
            val record = byteArrayOf(0xD1.toByte(), 0x01, payload.size.toByte(), 0x54) + payload
            ndefFile = byteArrayOf(
                ((record.size shr 8) and 0xFF).toByte(),
                (record.size and 0xFF).toByte(),
            ) + record
        }

        fun clear() {
            ndefFile = null
        }

        val isBroadcasting: Boolean get() = ndefFile != null
    }

    private var selectedFile = FILE_NONE

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        val apdu = commandApdu ?: return ERROR
        if (apdu.size < 4) return ERROR

        val cla = apdu[0].toInt() and 0xFF
        val ins = apdu[1].toInt() and 0xFF
        val p1 = apdu[2].toInt() and 0xFF
        val p2 = apdu[3].toInt() and 0xFF

        // SELECT by AID (00 A4 04 00 Lc <AID>)
        if (cla == 0x00 && ins == 0xA4 && p1 == 0x04) {
            if (apdu.size >= 5 + NDEF_AID.size &&
                apdu.copyOfRange(5, 5 + NDEF_AID.size).contentEquals(NDEF_AID)
            ) {
                selectedFile = FILE_NONE
                return OK
            }
            return FILE_NOT_FOUND
        }

        // SELECT file by id (00 A4 00 0C 02 <fileId>)
        if (cla == 0x00 && ins == 0xA4 && p1 == 0x00) {
            if (apdu.size >= 7) {
                val fid = ((apdu[5].toInt() and 0xFF) shl 8) or (apdu[6].toInt() and 0xFF)
                selectedFile = when (fid) {
                    0xE103 -> FILE_CC
                    0xE104 -> FILE_NDEF
                    else -> return FILE_NOT_FOUND
                }
                return OK
            }
            return FILE_NOT_FOUND
        }

        // READ BINARY (00 B0 <offsetHi> <offsetLo> <Le>)
        if (cla == 0x00 && ins == 0xB0) {
            val file = when (selectedFile) {
                FILE_CC -> CC_FILE
                FILE_NDEF -> ndefFile ?: return FILE_NOT_FOUND
                else -> return FILE_NOT_FOUND
            }
            val offset = (p1 shl 8) or p2
            val le = if (apdu.size >= 5) (apdu[4].toInt() and 0xFF).let { if (it == 0) 256 else it } else 256
            if (offset >= file.size) return FILE_NOT_FOUND
            val end = minOf(offset + le, file.size)
            return file.copyOfRange(offset, end) + OK
        }

        return ERROR
    }

    override fun onDeactivated(reason: Int) {
        selectedFile = FILE_NONE
    }
}
