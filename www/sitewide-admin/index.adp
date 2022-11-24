<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<h1>@title;noquote@</h1>
<include src="/packages/acs-tcl/lib/check-installed" &=resource_info &=version &=download_url>

<include src="/packages/acs-templating/lib/registered-urns" match="*:highcharts*">

<p>For developer information, look into the <a href="https://www.highcharts.com/docs/index">Highcharts Manual</a>.
<p>For a quick test, check the <a href="sample">Sample page</a>.
