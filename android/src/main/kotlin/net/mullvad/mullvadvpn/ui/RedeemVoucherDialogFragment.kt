package net.mullvad.mullvadvpn.ui

import android.app.Dialog
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.support.v4.app.DialogFragment
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.LayoutParams
import android.widget.EditText
import net.mullvad.mullvadvpn.R
import net.mullvad.mullvadvpn.ui.widget.Button
import net.mullvad.mullvadvpn.util.JobTracker
import net.mullvad.mullvadvpn.util.SegmentedInputFormatter

const val FULL_VOUCHER_CODE_LENGTH = "XXXX-XXXX-XXXX-XXXX".length

class RedeemVoucherDialogFragment : DialogFragment() {
    private val jobTracker = JobTracker()

    private var voucherInputIsValid = false
        set(value) {
            field = value
            updateRedeemButton()
        }

    private lateinit var redeemButton: Button
    private lateinit var voucherInput: EditText

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.redeem_voucher, container, false)

        voucherInput = view.findViewById<EditText>(R.id.voucher_code).apply {
            addTextChangedListener(ValidVoucherCodeChecker())
        }

        SegmentedInputFormatter(voucherInput, '-').apply {
            allCaps = true

            isValidInputCharacter = { character ->
                ('A' <= character && character <= 'Z') || ('0' <= character && character <= '9')
            }
        }

        redeemButton = view.findViewById<Button>(R.id.redeem).apply {
            setEnabled(false)
            setOnClickAction("action", jobTracker) {
                dismiss()
            }
        }

        view.findViewById<Button>(R.id.cancel).setOnClickAction("action", jobTracker) {
            activity?.onBackPressed()
        }

        return view
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val dialog = super.onCreateDialog(savedInstanceState)

        dialog.window?.setBackgroundDrawable(ColorDrawable(android.R.color.transparent))

        return dialog
    }

    override fun onStart() {
        super.onStart()

        dialog?.window?.setLayout(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
    }

    override fun onDestroyView() {
        jobTracker.cancelAllJobs()

        super.onDestroyView()
    }

    private fun updateRedeemButton() {
        redeemButton.setEnabled(voucherInputIsValid)
    }

    inner class ValidVoucherCodeChecker : TextWatcher {
        private var editRecursionCount = 0

        override fun beforeTextChanged(text: CharSequence, start: Int, count: Int, after: Int) {
            editRecursionCount += 1
        }

        override fun onTextChanged(text: CharSequence, start: Int, before: Int, count: Int) {}

        override fun afterTextChanged(text: Editable) {
            editRecursionCount -= 1

            if (editRecursionCount == 0) {
                voucherInputIsValid = text.length == FULL_VOUCHER_CODE_LENGTH
            }
        }
    }
}
