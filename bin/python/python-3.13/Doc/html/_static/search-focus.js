function isInputFocused() {
  const activeElement = document.activeElement;
  return (
    activeElement.tagName === 'INPUT' ||
    activeElement.tagName === 'TEXTAREA' ||
    activeElement.isContentEditable
  );
}

document.addEventListener('keydown', function(event) {
  if (event.key === '/') {
    if (!isInputFocused()) {
      // Prevent "/" from being entered in the search box
      event.preventDefault();

      // Set the focus on the search box
      const searchBox = document.getElementById('search-box');
      searchBox.focus();
    }
  }
});
