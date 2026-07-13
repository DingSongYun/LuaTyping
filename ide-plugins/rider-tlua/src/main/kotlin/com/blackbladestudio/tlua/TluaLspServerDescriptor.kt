package com.blackbladestudio.tlua

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.openapi.project.Project
import com.intellij.platform.lsp.api.ProjectWideLspServerDescriptor
import com.intellij.openapi.application.PathManager
import com.intellij.openapi.vfs.VirtualFile
import java.io.File

class TluaLspServerDescriptor(project: Project) : ProjectWideLspServerDescriptor(project, "TypingLua") {
    override fun isSupportedFile(file: VirtualFile): Boolean =
        file.extension.equals("lua", ignoreCase = true)

    override fun createCommandLine(): GeneralCommandLine {
        val exe = File(PathManager.getPluginsPath(), "rider-tlua/bin/bin/lua-language-server.exe")
        val cmd = GeneralCommandLine(exe.path)
        cmd.workDirectory = project.basePath ?: ""
        return cmd
    }
}
