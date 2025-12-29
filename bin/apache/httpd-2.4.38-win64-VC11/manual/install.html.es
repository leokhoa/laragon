<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="es" xml:lang="es"><head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="Content-Type" />
<!--
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
              This file is generated from xml source: DO NOT EDIT
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      -->
<title>Compilar e Instalar - Servidor HTTP Apache Versión 2.4</title>
<link href="./style/css/manual.css" rel="stylesheet" media="all" type="text/css" title="Main stylesheet" />
<link href="./style/css/manual-loose-100pc.css" rel="alternate stylesheet" media="all" type="text/css" title="No Sidebar - Default font size" />
<link href="./style/css/manual-print.css" rel="stylesheet" media="print" type="text/css" /><link rel="stylesheet" type="text/css" href="./style/css/prettify.css" />
<script src="./style/scripts/prettify.min.js" type="text/javascript">
</script>

<link href="./images/favicon.ico" rel="shortcut icon" /></head>
<body id="manual-page"><div id="page-header">
<p class="menu"><a href="./mod/">Módulos</a> | <a href="./mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="./glossary.html">Glosario</a> | <a href="./sitemap.html">Mapa del sitio web</a></p>
<p class="apache">Versión 2.4 del Servidor HTTP Apache</p>
<img alt="" src="./images/feather.png" /></div>
<div class="up"><a href="./"><img title="&lt;-" alt="&lt;-" src="./images/left.gif" /></a></div>
<div id="path">
<a href="http://www.apache.org/">Apache</a> &gt; <a href="http://httpd.apache.org/">Servidor HTTP</a> &gt; <a href="http://httpd.apache.org/docs/">Documentación</a> &gt; <a href="./">Versión 2.4</a></div><div id="page-content"><div id="preamble"><h1>Compilar e Instalar</h1>
<div class="toplang">
<p><span>Idiomas disponibles: </span><a href="./de/install.html" hreflang="de" rel="alternate" title="Deutsch">&nbsp;de&nbsp;</a> |
<a href="./en/install.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="./es/install.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="./fr/install.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="./ja/install.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="./ko/install.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="./tr/install.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a></p>
</div>
<div class="outofdate">Esta traducción podría estar
            obsoleta. Consulte la versión en inglés de la
            documentación para comprobar si se han producido cambios
            recientemente.</div>


    <p>Éste documento hace referencia a la compilación y la instalación del Apache 
    HTTP Server sólo para los sistemas Unix y  tipo Unix. Para la compilación e instalación en Windows  ir a  <a href="platform/windows.html">Usando Apache HTTP Server con Microsoft
    Windows</a> y <a href="platform/win_compiling.html">Compilando Apache para Microsoft Windows</a>.
    Para otras plataformas visite la documentación sobre <a href="platform/">plataformas</a>.</p>

    <p>Apache httpd usa <code>libtool</code> y <code>autoconf</code>
    para crear un entorno de compilación que se parece a muchos otros proyectos de código abierto</p>

    <p>Si está actualizando desde una versión menor a la siguiente (por
    ejemplo, 2.4.8 a 2.4.9), pasa a la sección de  <a href="#upgrading">actualización</a>.</p>

</div>
<div id="quickview"><a href="https://www.apache.org/foundation/contributing.html" class="badge"><img src="https://www.apache.org/images/SupportApache-small.png" alt="Support Apache!" /></a><ul id="toc"><li><img alt="" src="./images/down.gif" /> <a href="#overview">Descripción general para los impacientes</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#requirements">Requisitos</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#download">Descargar</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#extract">Descomprimir</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#configure">Configuración de la estructura de
directorios</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#compile">Build</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#install">Instalar</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#customize">Personalizar APACHE</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#test">Comprobar que la instalación
funciona</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#upgrading">Actualizar una instalación previa</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#thirdp">Paquetes de terceros</a></li>
</ul><h3>Consulte también</h3><ul class="seealso"><li><a href="programs/configure.html">Configuración del árbol de las fuentes de código</a></li><li><a href="invoking.html">Arrancando Apache httpd</a></li><li><a href="stopping.html">Parada y Reinicio</a></li><li><a href="#comments_section">Comentarios</a></li></ul></div>
<div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="overview" id="overview">Descripción general para los impacientes</a></h2>

    <table>
      
      <tr>
        <td><a href="#download">Descarga</a></td>

        <td>Descarga la última versión 
          desde <a href="http://httpd.apache.org/download.cgi#apache24">
          http://httpd.apache.org/download.cgi</a>
        </td>
      </tr>

      <tr>
        <td><a href="#extract">Extraer</a></td>

        <td><code>$ gzip -d httpd-<em>NN</em>.tar.gz<br />
         $ tar xvf httpd-<em>NN</em>.tar<br />
         $ cd httpd-<em>NN</em></code></td>
      </tr>

      <tr>
        <td><a href="#configure">Configura</a></td>

        <td><code>$ ./configure --prefix=<em>PREFIX</em></code>
        </td>
      </tr>

      <tr>
        <td><a href="#compile">Compila</a></td>

        <td><code>$ make</code> </td>
      </tr>

      <tr>
        <td><a href="#install">Instala</a></td>

        <td><code>$ make install</code> </td>
      </tr>

      <tr>
        <td><a href="#customize">Personalizalo</a></td>

        <td><code>$ vi <em>PREFIX</em>/conf/httpd.conf</code> </td>
      </tr>

      <tr>
        <td><a href="#test">Prueba</a></td>

        <td><code>$ <em>PREFIX</em>/bin/apachectl -k start</code>
        </td>
      </tr>
    </table>

    <p><em>NN</em> hay que reemplazarlo por el número de la versión menor, y <em>PREFIX</em> hay que reemplazarlo por la ruta en la que se va a instalar Apache. Si no especifica ningún valor en <em>PREFIX</em>, el valor por defecto que se toma es /usr/local/apache2.</p>

    <p>Cada parte del proceso de configuración e instalación se describe detalladamente más abajo, empezando por los requisitos para compilar e instalar Apache.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="requirements" id="requirements">Requisitos</a></h2>

    <p>Estos son los requisitos necesarios para compilar Apache:</p>

    <dl>
      <dt>APR y APR-Util</dt>
      <dd>Asegúrate de que tiene instalado ya en su sistema APR y APR-Util. Si no es así, o no quiere utilizar la versión que le proporciona el sistema, puede descargar la última versión de ambos APR y APR-Util de
      <a href="http://apr.apache.org/">Apache APR</a>, descomprimelo en
       <code>/httpd_source_tree_root/srclib/apr</code> y /httpd_source_tree_root<code>/srclib/apr-util</code>
      (cerciórate de que no existen directorios con números de versiones; por ejemplo,
      la distribución de APR debe estar en /httpd_source_tree_root/srclib/apr/) y usa el comando
      <code>./configure</code> <code>--con-las-opciones-incluidas-en-apr</code>.
      En algunas plataformas deberás instalar la parte correspondiente a los paquetes 
      <code>-dev</code> para permitir que httpd se genere contra la instalación de la copia de APR y APR-Util.</dd>

      <dt>Librería Compatible de expresiones regulares de Perl (PCRE)</dt>
      <dd>Esta librería es requerida, pero ya no incluido con httpd.
      Descarga el código fuente de <a href="http://www.pcre.org/">http://www.pcre.org</a>,
      o instala un Port o un  Paquete. Si la distrubución de su sistema no puede encontrar el escript pcre-config instalado por PCRE, seleccione utilizando el parámetro<code>--with-pcre</code>.En algunas plataformas,
      deberás instalar la correspondiente versión <code>-dev</code>
      del paquete para permitir a httpd que se genere contra la instalación de la copia del PCRE que se ha instalado.</dd>

      <dt>Espacio en disco</dt> 
      <dd>Compruebe que tiene disponibles al
      menos 50 MB de espacio libre en disco. Después de la
      instalación, Apache ocupa aproximadamente 10 MB. No
      obstante, la necesidad real de espacio en disco varía
      considerablemente en función de las opciones de
      configuración que elija y de los módulos externos que
      use, y como no del tamaño de la página web</dd>

      <dt>Systema de compilación ANSI-C</dt>
      <dd>Compruebe que tiene instalado un compilador de ANSI-C. Se recomienda el <a href="http://gcc.gnu.org/">Compilador GNU C
      (GCC)</a> de la <a href="http://www.gnu.org/">Free Software
      Foundation (FSF)</a> es el recomendado. Si no tiene instalado el GCC, entonces compruebe que
      el compilador que va a utilizar cumple con los estándares
      ANSI. Además, su <code>PATH</code> debe contener la
      ubicación donde de encuentran las herramientas básicas
      para compilar tales como <code>make</code>.</dd>

      <dt>Ajuste exacto del reloj del sistema</dt> 
      <dd>Los elementos
      del protocolo HTTP están expresados según la hora del
      día. Por eso, si quiere puede investigar como instalar alguna
      utilidad para sincronizar la hora de su sistema. Para esto,
      normalmente, se usan los programas <code>ntpdate</code> o
      <code>xntpd</code>, que están basados en el protocolo
      "Network Time Protocol" (NTP). Consulte el<a href="http://www.ntp.org">sitio web de NTP
      </a> para obtener más información sobre NTP y los
      servidores públicos de tiempo.</dd>

      <dt><a href="http://www.perl.org/">Perl 5</a>[OPCIONAL]</dt>
      <dd>Para algunos de los scripts de soporte como<code class="program"><a href="./programs/apxs.html">apxs</a></code> o <code class="program"><a href="./programs/dbmmanage.html">dbmmanage</a></code> (que están
      escritos en Perl) es necesario el intérprete de Perl 5 (las
      versiones 5.003 o posteriores son suficientes). Si el escript
      <code class="program"><a href="./programs/configure.html">configure</a></code> no se encuentra, no podrá usar los
	  escripts correspondientes que lo necesiten. Pero por supuesto
	  podrás compilar y usar Apache httpd.</dd>
    </dl>
</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="download" id="download">Descargar</a></h2>

    <p>Puede descargar Apache desde <a href="http://httpd.apache.org/download.cgi">la sección de
    descargas del sitio web de Apache</a> el cual tiene varios
    mirrors. Para la mayoría de los usuarios de Apache que tienen
    sistemas tipo Unix, se recomienda que se descarguen y compilen el
    código fuente. El proceso de compilación (descrito
    más abajo) es fácil, y permite adaptar el servidor
    Apache a sus necesidades. Además, las versiones de
    disponibles en archivos binarios no están siempre actualizadas
    con las últimas modificaciones en el código fuente. Si se
    descarga un binario, siga las instrucciones contenidas en el
    archivo <code>INSTALL.bindist</code> incluido en la
    distribución</p>

    <p>Después de la descarga, es importante que verifique que el
    archivo descargado del servidor HTTP Apache está completo y
    sin modificaciones.  Esto puede hacerlo comparando el archivo
    descargado (.tgz) con su firma PGP. Instrucciones detalladas de
    cómo hacer esto están disponibles en <a href="http://httpd.apache.org/download.cgi#verify"> la
    sección de descargas</a> junto con un ejemplo de cómo <a href="http://httpd.apache.org/dev/verification.html">usar
    PGP</a>.</p>

</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="extract" id="extract">Descomprimir</a></h2>

    <p>Extraer el código fuente del archivo .tgz del Servidor Apache HTTP que acabada 
      de descargar es muy fácil. Ejecute los siguientes comandos:</p>

<div class="example"><p><code>
$ gzip -d httpd-<em>NN</em>.tar.gz<br />
$ tar xvf httpd-<em>NN</em>.tar
</code></p></div>

    <p>Estos comandos crearán un nuevo directorio dentro del
    directorio en el que se encuentra y que contendrá el
    código fuente de distribución. Debe cambiarse a ese
    directorio con <code>cd</code> para proceder a compilar el
    servidor Apache.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="configure" id="configure">Configuración de la estructura de
directorios</a></h2>

    <p>El siguiente paso es configurar la estructura de directorios
    para su plataforma y sus necesidades personales. Esto se hace
    usando el script <code class="program"><a href="./programs/configure.html">configure</a></code> incluido en el directorio
    raíz de la distribución que acaba de descargar. (Los
    desarrolladores que se descarguen la versión del CVS de la
    estructura de directorios necesitarán tener instalados
    <code>autoconf</code> y <code>libtool</code>, y necesitarán
    ejecutar <code>buildconf</code> antes de continuar con los
    siguientes pasos. Esto no es preciso para las versiones
    oficiales.)</p>

    <p>Para configurar la estructura de directorios a partir del
    código fuente usando las opciones por defecto, solo tiene que
    ejecutar <code>./configure</code>.Para cambiar las opciones por
    defecto, <code class="program"><a href="./programs/configure.html">configure</a></code> acepta una serie de variables y
    opciones por la línea de comandos.</p>

    <p>La opción más importante es <code>--prefix</code>
    que es el directorio en el que Apache va a ser instalado después,
    porque Apache tiene que ser configurado para el directorio que se
    especifique para que funcione correctamente.  Es posible lograr un
    mayor control del lugar donde se van a instalar los ficheros de
    Apache con otras <a href="programs/configure.html#installationdirectories">opciones de
    configuración</a>.</p>

    <p>Llegados a este punto, puede especificar que <a href="programs/configure.html#optionalfeatures">características
    o funcionalidades</a> quiere incluir en Apache activando o
    desactivando <a href="mod/">modules</a>.Apache vine con una amplia
    selección de módulos incluidos por defecto. Que serán compilados como .
    <a href="dso.html">Objetos Compartidos (DSOs)</a> Que pueden ser activados
    o desactivados en tiempo de ejecución.
    También puede elegir por compilar módulos de forma estática usando las opciones
    <code>--enable-<var>module</var>=static</code>.</p>



    <p>Se pueden activar otros módulos usando la opción 
    <code>--enable-<var>module</var></code>, where
    <var>module</var> es el nombre del módulo sin el
    <code>mod_</code> y convirtiendo los guiones bajos que tenga en
    guiones normales.  Del mismo modo, puede desactivar los módulos con la
    opción <code>--disable-<var>module</var></code>. Tenga cuidado al utilizar esta opción, ya que
    <code class="program"><a href="./programs/configure.html">configure</a></code> no le avisará si el módulo que especifica no existe;
    simplemente ignorará esa opción.</p>

    <p>Además, a veces es necesario pasarle al script
    <code class="program"><a href="./programs/configure.html">configure</a></code> información adicional sobre donde esta
    su compilador, librerías o ficheros de cabecera.  Esto se puede
    hacer, tanto pasando variables de entorno, como pasandole opciones
    a <code class="program"><a href="./programs/configure.html">configure</a></code>.  Para más información, consulte el manual de
    <code class="program"><a href="./programs/configure.html">configure</a></code>. O use <code class="program"><a href="./programs/configure.html">configure</a></code> con la 
    opción <code>--help</code>.</p>

     <p>Para que se haga una idea sobre las posibilidades que tiene,
    aquí tiene un ejemplo típico que configura Apache para
    la ruta <code>/sw/pkg/apache</code> con un compilador y unos flags
    determinados, y además, con dos módulos adicionales
    <code class="module"><a href="./mod/mod_ldap.html">mod_ldap</a></code> y <code class="module"><a href="./mod/mod_ldap.html">mod_ldap</a></code> para
    cargarlos después a través del mecanismo DSO:</p>

<div class="example"><p><code>
      $ CC="pgcc" CFLAGS="-O2" \<br />
       ./configure --prefix=/sw/pkg/apache \<br />
       --enable-ldap=shared \<br />
       --enable-lua=shared
</code></p></div>

    <p>Cuando se ejecuta <code class="program"><a href="./programs/configure.html">configure</a></code> se comprueban que
    características o funcionalidades están disponibles en
    su sistema y se crean los Makefiles que serán usados a continuación
    para compilar el servidor. Esto tardará algunos minutos.</p>

    <p>Los detalles de todas las opciones de <code class="program"><a href="./programs/configure.html">configure</a></code> están disponibles
    en el manual de <code class="program"><a href="./programs/configure.html">configure</a></code> .</p>
  </div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="compile" id="compile">Build</a></h2>

    <p>Ahora puede compilar las diferentes partes que forman Apache
    simplemente ejecutando el siguiente comando:</p>

<div class="example"><p><code>$ make</code></p></div>

    <p>Por favor sea paciente llegado a este punto, ya que una configuración básica lleva unos minutos
      para su compilación, y el tiempo puede variar mucho dependiendo de su hardware 
      y del número de módulos que haya habilitado para la compilación.(Se recomienda añadir al make el
      parámetro -j3 como mínimo para que vaya más rápido)</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="install" id="install">Instalar</a></h2>

    <p>Ahora es el momento de instalar el paquete en el diretorio
    elegido en <em>PREFIX</em> (consulte más arriba la opción
    <code>--prefix</code>) ejecutando:</p>

<div class="example"><p><code>$ make install</code></p></div>

    <p>Este paso requiere de forma típica privilegios de root, ya que 
      el directorio de <em>PREFIX</em> es normalmente un directorio con 
      restricciones de permisos escritura.</p>

    <p>Si lo que esta es sólo actualizando, la instalación no sobreescribirá los
      archivos de configuración.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="customize" id="customize">Personalizar APACHE</a></h2>

    <p>Tras la instalación puede personalizarla, editando los 
    <a href="configuring.html">archivos de configuracion </a> en el directorio de
    <code><em>PREFIX</em>/conf/</code>.</p>

<div class="example"><p><code>$ vi <em>PREFIX</em>/conf/httpd.conf</code></p></div>

    <p>Échele un vistazo al Manual de Apache que está en
    <code><em>PREFIX</em>/docs/manual/</code> o consulta <a href="http://httpd.apache.org/docs/2.4/">http://httpd.apache.org/docs/2.4/</a> para la versión más
    reciente de este manual y su completa
    referencia de las <a href="mod/directives.html">directivas de configuracion</a> disponibles.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="test" id="test">Comprobar que la instalación
funciona</a></h2>

    <p>Ahora puedes  <a href="invoking.html">ejecutar</a> tu Apache
    HTTP server ejecutando directamente:</p>

<div class="example"><p><code>$ <em>PREFIX</em>/bin/apachectl -k start</code></p></div>

    <p>Ahora debe poder acceder a su primer documento
    bajo la URL <code>http://localhost/</code>. La página o documento que ve se encuentra en
    <code class="directive"><a href="./mod/core.html#documentroot">DocumentRoot</a></code>,
    que por norma general casi siempre será <code><em>PREFIX</em>/htdocs/</code>.
    Si quiere  <a href="stopping.html">parar</a> el servidor, puede hacerlo ejecutando:</p>

<div class="example"><p><code>$ <em>PREFIX</em>/bin/apachectl -k stop</code></p></div>
</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="upgrading" id="upgrading">Actualizar una instalación previa</a></h2>

    <p>El primer paso para actualizar una instalación anterior es
    leer las especificaciones de la versión y el fichero
    <code>CHANGES</code> en la distribución de código fuente
    que ha descargado para encontrar los cambios que puedan afectar a
    su instalación actual. Cuando el cambio sea entre versiones
    mayores(por ejemplo, de la 2.0 a 2.2 o de la 2.2 a la 2.4),
    entonces es más probable que haya diferencias importantes en
    la compilación y en la ejecución que necesitarán
    ajustes manuales. Todos los módulos necesitarán
    también ser actualizados para adaptarse a los cambios en el
    interfaz de programación (API) de módulos.</p>

    <p>Actualizando de una versión menor a la siguiente
      (por ejemplo, de la 2.2.55 a la  2.2.57) es mas fácil. El prodeso de realizar el <code>make install</code>
    no sobreescribirá ninguno de tus documentos existentes,archivos
    log, o archivos de configuración. De hecho, los desarrolladores están haciendo los esfuerzos
    necerarios para evitar cambios que generen incompatibilidades en las opciones de
    <code class="program"><a href="./programs/configure.html">configure</a></code>, la configuración al ser ejecutado, o el módulo de la API
    entre versiones menores. En la mayor parte de los casos debe poder usar un
    comando <code class="program"><a href="./programs/configure.html">configure</a></code> idéntico, un fichero de
    configuración idéntico, y todos sus módulos deben
    seguir funcionando.</p>

    <p>Para actualizar entre versiones menores, empecemos encontrando el archivo de configuración
    <code>config.nice</code> el directorio <code>de instalación</code> del servidor
    o en el directorio raiz del código fuente de tu antigua instalación. Este archivo contendrá
    los parámetros exactos para pasarle al 
    <code class="program"><a href="./programs/configure.html">configure</a></code> que usaste anteriormente para configurar tus directorios.
    Entonces, para actualizar su instalación de una versión a la
    siguinete, solo tiene que copiar el archivo
    <code>config.nice</code> a la estructura de directorios del
    código fuente de la nueva versión, editarlo, hacer
    cualquier cambio que desee, y ejecutarlo :</p>

    <div class="example"><p><code>
    $ ./config.nice<br />
    $ make<br />
    $ make install<br />
    $ <em>PREFIX</em>/bin/apachectl -k graceful-stop<br />
    $ <em>PREFIX</em>/bin/apachectl -k start<br />
    </code></p></div>

    <div class="warning">Tenga en cuenta que antes de poner una nueva
    versión de Apache en producción, debe siempre probarla
    antes en un entorno de pruebas. Por ejemplo, puede instalar y ejecutar la
    nueva versión junto con la antigua usando un
    <code>--prefix</code> diferente y un puerto diferente (modificando
    la directiva <code class="directive"><a href="./mod/mpm_common.html#listen">Listen</a></code>)
    para comprobar que no existe ninguna incompatibilidad antes de
    hacer la actualización definitiva.</div>

    <p>Puede pasarle argumentos adicionales a <code>config.nice</code>,
    que se agregarán a susopciones originales de <code class="program"><a href="./programs/configure.html">configure</a></code>:</p>

    <div class="example"><p><code>
    $ ./config.nice --prefix=/home/test/apache --with-port=90
    </code></p></div>
</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="thirdp" id="thirdp">Paquetes de terceros</a></h2>

    <p>Un gran número de terceros proporcionan sus propias 
    distribuciones empaquetadas del Apache HTTP Server para su
    instalación en plataformas específicas. Esto incluye las distintas
    distribuciones de Linux, varios paquetes de Windows de terceros,
    Mac OS X, Solaris, y muchos más.</p>

    <p>Nuestra licencia de software no sólo permite, sino que anima, 
    este tipo de redistribución. Sin embargo, se da lugar a una situación
    en la que el diseño y la configuración de los valores predeterminados
    de la instalación del servidor pueden diferir de lo que se indica
    en la documentación. Mientras lamentablemente, esta situación no es probable que cambie a corto plazo.</p>

    <p>Una <a href="http://wiki.apache.org/httpd/DistrosDefaultLayout">descripción
    de estas distribuciones de terceros </a> está siendo actualizada en el servidor de la WIKI de HTTP
    Server, y debería reflejar el actual estado de éstas distribuciones de terceros. 
    Sin embargo, tendrá que familiarizarse con los procedimientos de gestión
    e instalación de paquetes de su plataforma (SO) en particular.</p>

</div></div>
<div class="bottomlang">
<p><span>Idiomas disponibles: </span><a href="./de/install.html" hreflang="de" rel="alternate" title="Deutsch">&nbsp;de&nbsp;</a> |
<a href="./en/install.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="./es/install.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="./fr/install.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="./ja/install.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="./ko/install.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="./tr/install.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a></p>
</div><div class="top"><a href="#page-header"><img src="./images/up.gif" alt="top" /></a></div><div class="section"><h2><a id="comments_section" name="comments_section">Comentarios</a></h2><div class="warning"><strong>Notice:</strong><br />This is not a Q&amp;A section. Comments placed here should be pointed towards suggestions on improving the documentation or server, and may be removed again by our moderators if they are either implemented or considered invalid/off-topic. Questions on how to manage the Apache HTTP Server should be directed at either our IRC channel, #httpd, on Freenode, or sent to our <a href="http://httpd.apache.org/lists.html">mailing lists</a>.</div>
<script type="text/javascript"><!--//--><![CDATA[//><!--
var comments_shortname = 'httpd';
var comments_identifier = 'http://httpd.apache.org/docs/2.4/install.html';
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
<p class="menu"><a href="./mod/">Módulos</a> | <a href="./mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="./glossary.html">Glosario</a> | <a href="./sitemap.html">Mapa del sitio web</a></p></div><script type="text/javascript"><!--//--><![CDATA[//><!--
if (typeof(prettyPrint) !== 'undefined') {
    prettyPrint();
}
//--><!]]></script>
</body></html>