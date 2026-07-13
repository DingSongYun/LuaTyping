package com.blackbladestudio.tlua

import com.intellij.openapi.project.Project
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.platform.lsp.api.LspServerSupportProvider
import com.intellij.platform.lsp.api.LspServerStarter

class TluaLspServerSupportProvider : LspServerSupportProvider {
    override fun fileOpened(project: Project, file: VirtualFile, serverStarter: LspServerStarter) {
        if (file.extension.equals("lua", ignoreCase = true)) {
            serverStarter.ensureServerStarted(TluaLspServerDescriptor(project))
        }
    }
}
