const pydocthemeDark = document.getElementById('pydoctheme_dark_css')
const pygmentsDark = document.getElementById('pygments_dark_css')
const themeSelectors = document.getElementsByClassName('theme-selector')

function activateTheme(theme) {
  localStorage.setItem('currentTheme', theme);
  [...themeSelectors].forEach(e => e.value = theme)
  switch (theme) {
    case 'light':
      pydocthemeDark.media = 'not all'
      pygmentsDark.media = 'not all'
      break;
    case 'dark':
      pydocthemeDark.media = 'all'
      pygmentsDark.media = 'all'
      break;
    default:
      // auto
      pydocthemeDark.media = '(prefers-color-scheme: dark)'
      pygmentsDark.media = '(prefers-color-scheme: dark)'
  }
}

activateTheme(localStorage.getItem('currentTheme') || 'auto')
