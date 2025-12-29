<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="es" xml:lang="es"><head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="Content-Type" />
<!--
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
              This file is generated from xml source: DO NOT EDIT
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      -->
<title>Tutorial de Apache httpd: Introducción a los Server Side Includes
 - Servidor HTTP Apache Versión 2.4</title>
<link href="../style/css/manual.css" rel="stylesheet" media="all" type="text/css" title="Main stylesheet" />
<link href="../style/css/manual-loose-100pc.css" rel="alternate stylesheet" media="all" type="text/css" title="No Sidebar - Default font size" />
<link href="../style/css/manual-print.css" rel="stylesheet" media="print" type="text/css" /><link rel="stylesheet" type="text/css" href="../style/css/prettify.css" />
<script src="../style/scripts/prettify.min.js" type="text/javascript">
</script>

<link href="../images/favicon.ico" rel="shortcut icon" /></head>
<body id="manual-page"><div id="page-header">
<p class="menu"><a href="../mod/">Módulos</a> | <a href="../mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="../glossary.html">Glosario</a> | <a href="../sitemap.html">Mapa del sitio web</a></p>
<p class="apache">Versión 2.4 del Servidor HTTP Apache</p>
<img alt="" src="../images/feather.png" /></div>
<div class="up"><a href="./"><img title="&lt;-" alt="&lt;-" src="../images/left.gif" /></a></div>
<div id="path">
<a href="http://www.apache.org/">Apache</a> &gt; <a href="http://httpd.apache.org/">Servidor HTTP</a> &gt; <a href="http://httpd.apache.org/docs/">Documentación</a> &gt; <a href="../">Versión 2.4</a> &gt; <a href="./">How-To / Tutoriales</a></div><div id="page-content"><div id="preamble"><h1>Tutorial de Apache httpd: Introducción a los Server Side Includes
</h1>
<div class="toplang">
<p><span>Idiomas disponibles: </span><a href="../en/howto/ssi.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="../es/howto/ssi.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="../fr/howto/ssi.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="../ja/howto/ssi.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="../ko/howto/ssi.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a></p>
</div>

<p>Los Server Side Includes (Inclusiones en la parte Servidor) facilitan un método para añadir contenido dinámico a documentos HTML existentes.</p>
</div>
<div id="quickview"><a href="https://www.apache.org/foundation/contributing.html" class="badge"><img src="https://www.apache.org/images/SupportApache-small.png" alt="Support Apache!" /></a><ul id="toc"><li><img alt="" src="../images/down.gif" /> <a href="#related">Introducción</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#what">¿Qué son los SSI?</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#configuring">Configurar su servidor para permitir SSI</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#basic">Directivas SSI básicas</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#additionalexamples">Más ejemplos</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#config">¿Qué más puedo configurar?</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#exec">Ejecutando comandos</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#advanced">Técnicas avanzadas de SSI</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#conclusion">Conclusión</a></li>
</ul><h3>Consulte también</h3><ul class="seealso"><li><a href="#comments_section">Comentarios</a></li></ul></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="related" id="related">Introducción</a></h2>
 <table class="related"><tr><th>Módulos Relacionados</th><th>Directivas Relacionadas</th></tr><tr><td><ul><li><code class="module"><a href="../mod/mod_include.html">mod_include</a></code></li><li><code class="module"><a href="../mod/mod_cgi.html">mod_cgi</a></code></li><li><code class="module"><a href="../mod/mod_expires.html">mod_expires</a></code></li></ul></td><td><ul><li><code class="directive"><a href="../mod/core.html#options">Options</a></code></li><li><code class="directive"><a href="../mod/mod_include.html#xbithack">XBitHack</a></code></li><li><code class="directive"><a href="../mod/mod_mime.html#addtype">AddType</a></code></li><li><code class="directive"><a href="../mod/core.html#setoutputfilter">SetOutputFilter</a></code></li><li><code class="directive"><a href="../mod/mod_setenvif.html#browsermatchnocase">BrowserMatchNoCase</a></code></li></ul></td></tr></table>

    <p>Este artículo trata sobre los Server Side Includes, generalmente llamados SSI.
     En este artículo, hablaremos sobre cómo configurar su servidor para permitir SSI,
      y de técnicas básicas de SSI para añadir contenido dinámico a sus páginas 
      HTML existentes.</p>

    <p>Más adelante también hablaremos de algunas técnicas más avanzadas que 
    pueden usarse con SSI, tales como declaraciones condicionales en sus directivas SSI.</p>

</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="what" id="what">¿Qué son los SSI?</a></h2>

    <p>SSI (Server Side Includes) son directivas que se introducen en páginas HTML y son 
        evaluadas por el servidor mientras éste las sirve. Le permiten añadir 
        contenido generado de manera dinámica a sus páginas HTML existentes sin tener 
        que servir una página entera a través de un programa CGI, u otra tecnología 
        para generar contenido dinámico.</p>

    <p>Por ejemplo, podría colocar una directiva en una página existente de HTML 
        de esta manera:</p>

    <div class="example"><p><code>
    &lt;!--#echo var="DATE_LOCAL" --&gt;
    </code></p></div>

    <p>Y, cuando se sirve la página, este fragmento será evaluado y sustituido con su resultado:</p>

    <div class="example"><p><code>
    Tuesday, 15-Jan-2013 19:28:54 EST
    </code></p></div>

    <p>La decisión sobre cuándo usar SSI, o de cuándo generar una página al completo con algún programa, suele depender generalmente de la cantidad de contenido estático que contiene, y cuánto de esa página tiene que ser recalculado cada vez que ésta se sirve. SSI es un buen método para añadir pequeñas partes de información, tales como la hora actual - como se ha mostrado más arriba. Pero si la mayoría de su página se tiene que generar en el momento en el que se está sirviendo, necesita buscar otra opción más adecuada que no sea SSI.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="configuring" id="configuring">Configurar su servidor para permitir SSI</a></h2>


    <p>Para permitir SSI en su servidor, debe tener la siguiente directiva en su fichero <code>httpd.conf</code> , o en un fichero 
    <code>.htaccess</code>:</p>
<pre class="prettyprint lang-config">Options +Includes</pre>


    <p>Esto le dice a Apache que quiere permitir que se examinen los ficheros buscando directivas SSI. Tenga en cuenta que la mayoría de las configuraciones contienen múltiples directivas <code class="directive"><a href="../mod/core.html#options">Options</a></code> que pueden sobreescribirse las unas a las otras. Probablemente necesitará aplicar <code>Options</code> al directorio específico donde quiere SSI activado para asegurarse de que se evalúa en último lugar y por tanto se acabará aplicando.</p>

    <p>No todos los ficheros se examinan buscando directivas SSI. Usted Le tiene que indicar a Apache qué ficheros se tienen que examinar. Hay dos formas de hacer esto. Puede decirle a Apache que examine cualquier fichero con una extensión determinada, como por ejemplo <code>.shtml</code>, con las siguientes directivas:</p>
<pre class="prettyprint lang-config">AddType text/html .shtml
AddOutputFilter INCLUDES .shtml</pre>


    <p>Una desventaja de este método es que si quisiera añadir directivas SSI a una página ya existente, tendría que cambiar el nombre de la página, y todos los enlaces que apuntasen a esa página, todo para poder darle la extensión <code>.shtml</code> y que esas directivas sean interpretadas.</p>

    <p>El otro método es usar la directiva <code class="directive"><a href="../mod/mod_include.html#xbithack">XBitHack</a></code> :</p>
<pre class="prettyprint lang-config">XBitHack on</pre>


    <p><code class="directive"><a href="../mod/mod_include.html#xbithack">XBitHack</a></code> le dice a Apache que examine ficheros buscando directivas SSI si los ficheros tienen el bit de ejecución configurado. Asi que para añadir directivas SSI a una página existente, en lugar de tener que cambiarle el nombre, solo tendría que convertirla en ejecutable usando <code>chmod</code>.</p>
<div class="example"><p><code>
        chmod +x pagename.html
</code></p></div>

    <p>Una breve recomendación de qué no hay que hacer. Ocasionalmente vemos gente recomendar que le diga a Apache que examine todos los ficheros 
    <code>.html</code> para activar SSI, para no tener que lidiar renombrando los ficheros a <code>.shtml</code>. Quizás estas personas no hayan oido hablar de <code class="directive"><a href="../mod/mod_include.html#xbithack">XBitHack</a></code>. Lo que hay que tener en cuenta, es que haciendo eso, está pidiendo al Apache que lea cada uno de los ficheros que manda al cliente, incluso si no contenien directivas SSI. Esto puede ralentizar bastante el servidor, y no es una buena idea.</p>

    <p>Por supuesto, en Windows, no hay tal cosa como la configuración del bit de ejecución, así que esto limita las opciones un poco.</p>

    <p>En su configuración por defecto, Apache no envía la fecha de última modificación o la longitud de contenido de páginas SSI porque es dificil calcular estos valores para contenido dinámico. Esto puede impedir que se cachee un documento, y dar como resultado en apareciencia un rendimiento más lento del cliente. Hay dos maneras de solucionar esto:</p>

    <ol>
      <li>Usando la configuración <code>XBitHack Full</code>. Esto le indica a apache que determine la fecha de última modificación mirando sólo la fecha del fichero que se ha solicitado originalmente, obviando la modificación de cualquier otro fichero al que se hace referencia mediante SSI.</li>

      <li>Use las directivas facilitadas por <code class="module"><a href="../mod/mod_expires.html">mod_expires</a></code> para configurar una expiración específica de tiempo en sus ficheros, y así hacer saber a proxies o navegadores web que es aceptable cachearlos.</li>
    </ol>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="basic" id="basic">Directivas SSI básicas</a></h2>

    <p>Las directivas SSI tienen la sintaxis siguiente:</p>
<div class="example"><p><code>
        &lt;!--#function attribute=value attribute=value ... --&gt;
</code></p></div>

    <p>Se formatean como comentarios HTML, así si no tiene SSI habilitado correctamente, el navegador las obviará, pero todavía serán visibles en el fichero HTML. Si tiene SSI configurado correctamente, la directiva será reemplazada con su propio resultado.</p>

    <p>Esta función es una de tantas, y hablaremos de algunas de ellas más adelante. Por ahora, aquí mostramos unos ejemplos de lo que puede hacer con SSI.</p>

<h3><a name="todaysdate" id="todaysdate">La fecha de hoy</a></h3>

<div class="example"><p><code>
        &lt;!--#echo var="DATE_LOCAL" --&gt;
</code></p></div>

    <p>La función <code>echo</code> sencillamente muestra el valor de una variable. Hay muchas variables estándar que incluyen un conjunto de variables de entorno disponibles para programas CGI. También puede definir sus propias variables con la función <code>set</code>.</p>

    <p>Si no le gusta el formato en el que se imprime la fecha, puede usar la función <code>config</code>, con un atributo
    <code>timefmt</code> para modificar ese formato.</p>

<div class="example"><p><code>
        &lt;!--#config timefmt="%A %B %d, %Y" --&gt;<br />
        Today is &lt;!--#echo var="DATE_LOCAL" --&gt;
</code></p></div>


<h3><a name="lastmodified" id="lastmodified">Fecha de modificación del fichero</a></h3>

<div class="example"><p><code>
        La última modificación de este documento &lt;!--#flastmod file="index.html" --&gt;
</code></p></div>

    <p>Esta función también está sujeta a configuraciones de formato de 
        <code>timefmt</code>.</p>


<h3><a name="cgi" id="cgi">Incluyendo los resultados de un programa CGI</a></h3>

    <p>Este es uno de los usos más comunes de SSI - para sacar el resultado de un programa CGI, tal y como ocurre con el que fuera el programa favorito de todos, un ``contador de visitas.''</p>

<div class="example"><p><code>
        &lt;!--#include virtual="/cgi-bin/counter.pl" --&gt;
</code></p></div>


</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="additionalexamples" id="additionalexamples">Más ejemplos</a></h2>


    <p>A continuación hay algunos ejemplos específicos de cosas que puede hacer con SSI en sus documentos HTML.</p>

<h3><a name="docmodified" id="docmodified">¿Cuándo fue modificado este documento?</a></h3>

    <p>Antes mencionamos que puede usar SSI para informar al usuario cuando el documento ha sido modificado por última vez. Aun así, el método actual para hacerlo se dejó en cuestión. El código que se muestra a continuación, puesto en un documento HTML, pondrá ese sello de tiempo en su página. Por descontado, tendrá que tener SSI habilitado correctamente, como se indicó más arriba.</p>
<div class="example"><p><code>
        &lt;!--#config timefmt="%A %B %d, %Y" --&gt;<br />
        Ultima modificación de este fichero &lt;!--#flastmod file="ssi.shtml" --&gt;
</code></p></div>

    <p>Obviamente, necesitará sustituir el nombre de fichero
    <code>ssi.shtml</code> con el nombre real del fichero al que usted hace referencia. Esto puede ser inconveniente si solo está buscando un trozo genérico de código que pueda copiar y pegar en cualquier fichero, asi que probablemente necesite usar la variable <code>LAST_MODIFIED</code> en su lugar:</p>
<div class="example"><p><code>
        &lt;!--#config timefmt="%D" --&gt;<br />
        Última modificación de este fichero &lt;!--#echo var="LAST_MODIFIED" --&gt;
</code></p></div>

    <p>Para más detalles sobre el formato <code>timefmt</code>, vaya a su buscador favorito y busque <code>strftime</code>. La sintaxis es la misma.</p>


<h3><a name="standard-footer" id="standard-footer">Incluyendo un pie de página estándar</a></h3>


    <p>Si gestiona un sitio que tiene más de unas cuantas páginas, probablemente se de cuenta de que modificar todas esa páginas es un auténtico engorro, especialmente si trata de mantener una apareciencia homogénea en todas ellas.</p>

    <p>Si usa un Include de fichero para la cabecera y/o pie de página puede reducir la carga de trabajo de estas actualizaciones. Solo tiene que hacer un sólo pie de página, y después incluirlo en cada página con el comando SSI <code>include</code>. La función <code>include</code>
    puede determinar qué fichero incluir cuando usa el atributo
    <code>file</code>, o el atributo <code>virtual</code>. El atributo <code>file</code> es una ruta de fichero, <em>relativa al directorio actual</em>. Eso significa que no puede ser una ruta de fichero absoluta (que comienza con /), ni tampoco puede contener ../ como parte de la ruta. El atributo <code>virtual</code> es probablemente más útil, y debería especificar una URL relativa al documento que se está sirviendo. Puede empezar con una /, pero debe estar en el mismo servidor que el fichero que se está sirviendo.</p>
<div class="example"><p><code>
        &lt;!--#include virtual="/footer.html" --&gt;
</code></p></div>

    <p>Frecuentemente combinaremos las dos últimas, poniendo una directiva
    <code>LAST_MODIFIED</code> dentro de un fichero de pie de página que va a ser incluido. Se pueden encontrar directivas SSI en el fichero que se incluye, las inclusiones pueden anidarse - lo que quiere decir, que el fichero incluido puede incluir otro fichero, y así sucesivamente.</p>


</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="config" id="config">¿Qué más puedo configurar?</a></h2>


    <p>Además de poder configurar el formato de la hora, también puede configurar dos cosas más.</p> 

    <p>Generalmente, cuando algo sale mal con sus directivas SSI, obtiene el mensaje (ha ocurrido un error procesando esta directiva)</p>
<div class="example"><p><code>
        [an error occurred while processing this directive]
</code></p></div>

    <p>Si quiere cambiar ese mensaje por otra cosa, puede hacerlo con el atributo <code>errmsg</code> para la función
    <code>config</code>:</p>
<div class="example"><p><code>
        &lt;!--#config errmsg="[Parece que no sabe cómo usar SSI]" --&gt;
</code></p></div>

    <p>Afortunadamente, los usuarios finales nunca verán este mensaje, porque habrá resuelto todos los problemas con sus directivas SSI antes de publicar su página web. (¿Verdad?)</p>

    <p>Y puede configurar el formato en el que los tamaños de fichero se muestran con el formato <code>sizefmt</code>. Puede especificar
    <code>bytes</code> para un recuento total en bytes, o
    <code>abbrev</code> para un número abreviado en Kb o Mb, según sea necesario.</p>
    </div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="exec" id="exec">Ejecutando comandos</a></h2>
    

    <p> Puede usar la función <code>exec</code> para ejecutar comandos. Y SSI puede ejecutar un comando usando la shell (<code>/bin/sh</code>, para ser más precisos - o la shell de DOS , si está en Win32). Lo siguiente, por ejemplo, le dará un listado de ficheros en un directorio.</p>
<div class="example"><p><code>
        &lt;pre&gt;<br />
        &lt;!--#exec cmd="ls" --&gt;<br />
        &lt;/pre&gt;
</code></p></div>

    <p>o, en Windows</p>
<div class="example"><p><code>
        &lt;pre&gt;<br />
        &lt;!--#exec cmd="dir" --&gt;<br />
        &lt;/pre&gt;
</code></p></div>

    <p>Notará un formato estraño con esta directiva en Windows, porque el resultado de <code>dir</code> contiene la cadena de caracterers ``&lt;<code>dir</code>&gt;'' ,que confunde a los navegadores.</p>

    <p>Tenga en cuenta de que esta característica es muy peligrosa, puesto que ejecutará cualquier código que esté especificado con la etiqueta 
    <code>exec</code>. Si tiene una situación en la que los usuarios pueden editar contenido en sus páginas web, tales como por ejemplo un ``registro de visitas'', asegúrese de tener esta característica deshabilitada. Puede permitir SSI, pero no la característica <code>exec</code>, con el argumento <code>IncludesNOEXEC</code> en la directiva <code>Options</code>.</p>
    </div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="advanced" id="advanced">Técnicas avanzadas de SSI</a></h2>


    <p>Además de mostrar contenido, SSI en Apache da la opción de configurar variables y usar esas variables en comparaciones y condicionales.</p>

<h3><a name="variables" id="variables">Configurando Variables</a></h3>

    <p>Usando la directiva <code>set</code>, puede configurar variables para su uso posterior. La sintaxis es como sigue:</p>
<div class="example"><p><code>
        &lt;!--#set var="name" value="Rich" --&gt;
</code></p></div>

    <p>Además de configurar valores literales como esto, puede usar cualquier otra variable, incluyendo <a href="../env.html">variables de entorno</a> o las variables que se han mencionado antes (como por ejemplo <code>LAST_MODIFIED</code>) para dar valores a sus variables. Podrá especificar que algo es una vaiable, en lugar de una cadena de caracters literal, usando el símbolo del dolar ($) antes del nombre de la variable.</p>

    <div class="example"><p><code> &lt;!--#set var="modified" value="$LAST_MODIFIED" --&gt;
    </code></p></div>

    <p>Para poner el símbolo del dolar de manera literal en un valor de su variable tendrá que escapar el símbolo del dolar con una barra "\".</p>
<div class="example"><p><code>
        &lt;!--#set var="cost" value="\$100" --&gt;
</code></p></div>

    <p>Por último, si quiere poner una variable entre medias de una cadena de caracteres más larga, y se da la coincidencia de que el nombre de la variable se encontrará con otros caracteres, y de esta manera se confundirá con otros caracteres, puedes poner el nombre de la variable entre llaves, y así eliminar la confusión. (Es dificil encontrar un buen ejemplo para esto, pero con éste a lo mejor entiende lo que tratamos de transmitir.)</p>
<div class="example"><p><code>
        &lt;!--#set var="date" value="${DATE_LOCAL}_${DATE_GMT}" --&gt;
</code></p></div>


<h3><a name="conditional" id="conditional">Expresiones condicionales</a></h3>


    <p>Ahora que tenemos variables, y somos capaces de comparar sus valores, podemos usarlas para expresar condicionales. Esto permite a SSI ser un cierto tipo de lenguaje de programación diminuto.
    <code class="module"><a href="../mod/mod_include.html">mod_include</a></code> provee una estrucura <code>if</code>,
    <code>elif</code>, <code>else</code>, <code>endif</code>
    para construir declaraciones condicionales. Esto le permite generar de manera efectiva multitud de páginas lógicas desde tan solo una página.</p>

    <p>La estructura de este sistema condicional es:</p>
<div class="example"><p><code>
    &lt;!--#if expr="test_condition" --&gt;<br />
    &lt;!--#elif expr="test_condition" --&gt;<br />
    &lt;!--#else --&gt;<br />
    &lt;!--#endif --&gt;
</code></p></div>

    <p>Una <em>test_condition</em> puede ser cualquier tipo de comparación lógica - o bien comparando valores entre ellos, o probando la ``verdad'' (o falsedad) de un valor en particular. (Una cadena de caracteres cualquiera es verdadera si no está vacía.) Para una lista completa de operadores de comparación, vea la documentación de <code class="module"><a href="../mod/mod_include.html">mod_include</a></code>.</p>

    <p>Por ejemplo, si quiere personalizar el texto en su página web basado en la hora actual, puede usar la siguiente receta, colocada en su página HTML:</p>

    <div class="example"><p><code>
    Good
    &lt;!--#if expr="%{TIME_HOUR} &lt;12" --&gt;<br />
    morning!<br />
    &lt;!--#else --&gt;<br />
    afternoon!<br />
    &lt;!--#endif --&gt;<br />
    </code></p></div>

    <p>Cualquier otra variable (o bien las que defina usted, o variables de entorno normales) puede usarse en declaraciones condicionales.
    Vea <a href="../expr.html">Expresiones en el Servidor Apache HTTP</a> para más información sobre el motor de evaluación de expresiones.</p>

    <p>Con la habilidad de Apache de configurar variables de entorno con directivas <code>SetEnvIf</code>, y otras directivas relacionadas,
    esta funcionalidad puede llevarle a hacer una gran variedad de contenido dinámico en la parte de servidor sin tener que depender de una aplicación web al completo.</p>

</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="conclusion" id="conclusion">Conclusión</a></h2>

    <p>Desde luego SSI no es un reemplazo para CGI u otras tecnologías que se usen para generar páginas web dinámicas. Pero es un gran método para añadir pequeñas cantidaddes de contenido dinámico a páginas web, sin hacer mucho más trabajo extra.</p>
</div></div>
<div class="bottomlang">
<p><span>Idiomas disponibles: </span><a href="../en/howto/ssi.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="../es/howto/ssi.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="../fr/howto/ssi.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="../ja/howto/ssi.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="../ko/howto/ssi.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a></p>
</div><div class="top"><a href="#page-header"><img src="../images/up.gif" alt="top" /></a></div><div class="section"><h2><a id="comments_section" name="comments_section">Comentarios</a></h2><div class="warning"><strong>Notice:</strong><br />This is not a Q&amp;A section. Comments placed here should be pointed towards suggestions on improving the documentation or server, and may be removed again by our moderators if they are either implemented or considered invalid/off-topic. Questions on how to manage the Apache HTTP Server should be directed at either our IRC channel, #httpd, on Freenode, or sent to our <a href="http://httpd.apache.org/lists.html">mailing lists</a>.</div>
<script type="text/javascript"><!--//--><![CDATA[//><!--
var comments_shortname = 'httpd';
var comments_identifier = 'http://httpd.apache.org/docs/2.4/howto/ssi.html';
(function(w, d) {
    if (w.location.hostname.toLowerCase() == "httpd.apache.org") {
        d.write('<div id="comments_thread"><\/div>');
        var s = d.createElement('script');
        s.type = 'text/javascript';
        s.async = true;
        s.src = 'https://comments.apache.org/show_comments.lua?site=' + comments_shortname + '&page=' + comments_identifier;
        (d.getElementsByTagName('head')[0] || d.getElementsByTagName('body')[0]).appendChild(s);
    }
    else { 
        d.write('<div id="comments_thread">Comments are disabled for this page at the moment.<\/div>');
    }
})(window, document);
//--><!]]></script></div><div id="footer">
<p class="apache">Copyright 2019 The Apache Software Foundation.<br />Licencia bajo los términos de la <a href="http://www.apache.org/licenses/LICENSE-2.0">Apache License, Version 2.0</a>.</p>
<p class="menu"><a href="../mod/">Módulos</a> | <a href="../mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="../glossary.html">Glosario</a> | <a href="../sitemap.html">Mapa del sitio web</a></p></div><script type="text/javascript"><!--//--><![CDATA[//><!--
if (typeof(prettyPrint) !== 'undefined') {
    prettyPrint();
}
//--><!]]></script>
</body></html>