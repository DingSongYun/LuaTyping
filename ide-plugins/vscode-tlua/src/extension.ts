import * as path from "path";
import * as vscode from "vscode";
import { LanguageClient, LanguageClientOptions, ServerOptions } from "vscode-languageclient/node";

export function activate(context: vscode.ExtensionContext) {
  const configured = vscode.workspace.getConfiguration("tluaLsp").get<string>("serverPath");
  const serverPath = configured && configured.length > 0
    ? configured
    : path.join(context.extensionPath, "server", "bin", "lua-language-server.exe");

  const serverOptions: ServerOptions = {
    run: { command: serverPath },
    debug: { command: serverPath },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "lua" }],
  };

  const client = new LanguageClient(
    "tluaLanguageServer",
    "TypingLua Language Server",
    serverOptions,
    clientOptions
  );

  context.subscriptions.push(client);
  client.start();
}

export function deactivate() {}
