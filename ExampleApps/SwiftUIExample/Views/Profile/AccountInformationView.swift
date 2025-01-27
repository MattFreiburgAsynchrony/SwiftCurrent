//
//  UpdatedAccountInformationView.swift
//  SwiftUIExample
//
//  Created by Tyler Thompson on 7/15/21.
//
//  Copyright © 2021 WWT and Tyler Thompson. All rights reserved.

import SwiftUI
import SwiftCurrent
import SwiftCurrent_SwiftUI

struct AccountInformationView: View, FlowRepresentable {
    @State var password = "supersecure"
    @State var email = "SwiftCurrent@wwt.com"
    @State var emailWorkflowLaunched = false
    @State var passwordWorkflowLaunched = false

    let inspection = Inspection<Self>() // ViewInspector
    weak var _workflowPointer: AnyFlowRepresentable?

    var body: some View {
        VStack(alignment: .leading, spacing: 25) { // swiftlint:disable:this closure_body_length
            // IMPORTANT THAT THIS ONLY SHOWS WHEN NOT UPDATING
            if !emailWorkflowLaunched {
                HStack(spacing: 15) {
                    Image.account
                        .iconStyle()
                        .foregroundColor(.icon)
                    Text("Email: ")
                    Text(email)
                    Spacer()
                    Button {
                        withAnimation {
                            emailWorkflowLaunched = true
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .iconStyle()
                            .foregroundColor(.icon)
                    }
                }
                .textEntryStyle()
            } else {
                WorkflowLauncher(isLaunched: $emailWorkflowLaunched.animation(), startingArgs: email) {
                    thenProceed(with: MFAView.self) {
                        thenProceed(with: ChangeEmailView.self)
                    }
                }.onFinish {
                    guard case .args(let newEmail as String) = $0 else { return }
                    email = newEmail
                    withAnimation {
                        emailWorkflowLaunched = false
                    }
                }
            }

            if !passwordWorkflowLaunched {
                HStack(spacing: 15) {
                    Image.password
                        .iconStyle()
                        .foregroundColor(.icon)
                    Text("Password: ")
                    SecureField(text: $password) { EmptyView() }.disabled(true)
                    Spacer()
                    Button {
                        withAnimation {
                            passwordWorkflowLaunched = true
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .iconStyle()
                            .foregroundColor(.icon)
                    }
                }
                .textEntryStyle()
            } else {
                WorkflowLauncher(isLaunched: $passwordWorkflowLaunched.animation(), startingArgs: password) {
                    thenProceed(with: MFAView.self) {
                        thenProceed(with: ChangePasswordView.self)
                            .presentationType(.modal)
                            .applyModifiers { cpv in
                                NavigationView {
                                    VStack {
                                        cpv
                                            .padding()
                                            .background(Color.card)
                                            .cornerRadius(35)
                                            .padding(.horizontal, 20)
                                            .navigationTitle("Update password")

                                        Spacer()
                                    }
                                }
                            }
                    }
                }.onFinish {
                    guard case .args(let newPassword as String) = $0 else { return }
                    password = newPassword
                    passwordWorkflowLaunched = false
                }
            }
        }.onReceive(inspection.notice) { inspection.visit(self, $0) } // ViewInspector
    }
}

struct UpdatedAccountInformationView_Previews: PreviewProvider {
    static var previews: some View {
        AccountInformationView()
            .preferredColorScheme(.dark)
            .background(Color.primaryBackground)
    }
}
