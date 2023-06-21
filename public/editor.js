

var editor = ace.edit("editor");
editor.setTheme("ace/theme/monokai");
editor.session.setMode("ace/mode/javascript");


document.addEventListener('keydown', e => {
    if (e.ctrlKey && e.key === 's') {
      // Prevent the Save dialog to open
      e.preventDefault();
      // Place your code here
      console.log('CTRL + S');
      fetch(window.location.href, {
        method: "POST",
        body: editor.getValue(),
        headers: {
            "Content-type": "text; charset=UTF-8"
        }
      });
    }
    
  });