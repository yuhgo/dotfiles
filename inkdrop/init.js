inkdrop.onEditorLoad((editor) => {
  const CodeMirror = require('codemirror');
  const { cm } = editor;

  // Vimプラグインの読み込みを待つ
  setTimeout(() => {
    const Vim = inkdrop.packages.getLoadedPackage('vim').mainModule.Vim;

    // Map keys
    Vim.map('jj', '<Esc>', 'insert'); // in insert mode
    Vim.map('Y', 'y$'); // in normal mode
  }, 500);

  // Vimコマンドハンドラー
  const handleVimCommand = (command) => {
    const _vim = CodeMirror.Vim;

    return () => {
      const vim = _vim.maybeInitVimState(cm);
      return cm.operation(() => {
        cm.curOp.isVimOp = true;
        try {
          _vim.commandDispatcher.processCommand(cm, vim, command);
        } catch (e) {
          // clear VIM state in case it's in a bad state.
          cm.state.vim = undefined;
          _vim.maybeInitVimState(cm);
          throw e;
        }
        return true;
      });
    };
  };

  const vimMoveUp = handleVimCommand({
    keys: 'k',
    type: 'motion',
    motion: 'moveByLines',
    motionArgs: { forward: false, linewise: true },
  });

  const vimMoveDown = handleVimCommand({
    keys: 'j',
    type: 'motion',
    motion: 'moveByLines',
    motionArgs: { forward: true, linewise: true },
  });

  // カスタムコマンド定義
  inkdrop.commands.add(document.body, 'vim:5-move-down', () => {
    for (let i = 0; i < 5; i++) {
      vimMoveDown();
    }
  });

  inkdrop.commands.add(document.body, 'vim:5-move-up', () => {
    for (let i = 0; i < 5; i++) {
      vimMoveUp();
    }
  });
});
