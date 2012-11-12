<xsl:transform
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:style="http://saxonica.com/ns/html-style-property"
xmlns:f="urn:internal.function"
extension-element-prefixes="ixsl"
version="2.0"
>

<xsl:variable name="nav-panel" select="id('nav',ixsl:page())"/>
<xsl:variable name="navlist" select="$nav-panel/ul/li"/>

<xsl:function name="f:getIdParts" as="item()+">
<xsl:param name="id"/>
<xsl:variable name="b4" select="substring-before($id , '[')"/>
<xsl:variable name="predStart" select="string-length($b4) + 2" as="xs:double"/>
<xsl:sequence
select="if ($b4 eq '') then 1 else
number(
substring($id , $predStart, string-length($id) - $predStart))"/>
<xsl:sequence
select="if ($b4 eq '') then $id else $b4"/>
</xsl:function>

<xsl:template name="navToNewTreeItem">
<xsl:variable name="keyCode" as="xs:double" select="ixsl:get(ixsl:event(), 'keyCode')"/>
<xsl:if test="$keyCode = (38, 40, 37, 39, 13)">
<xsl:sequence select="js:preventDefault(ixsl:event())"/>
<xsl:variable name="isPrev" select="$keyCode = 38"/>
<xsl:variable name="c" select="js:getHotItem()/.."/>

<xsl:choose>
<xsl:when test="$keyCode eq 37">
<xsl:for-each select="$c">
<xsl:if test="@class eq 'open'">
<ixsl:set-attribute name="class" select="'closed'"/>
</xsl:if>
</xsl:for-each>
</xsl:when>
<xsl:otherwise>
<xsl:variable name="new-li"
select="if ($keyCode = 38) then

(($c/preceding-sibling::li union
$c/preceding-sibling::li/descendant::li union
$c/ancestor::li/preceding-sibling::li union
$c/parent::ul/parent::li)
[not(ancestor::li/@class = 'closed')])
[last()]

else if ($keyCode = 40) then

($c/following-sibling::li union
$c/descendant::li union
$c/ancestor::li/following-sibling::li
)[not(ancestor::li/@class = 'closed')]
[1]
else
$c"/>

<ixsl:schedule-action wait="5">
<xsl:call-template name="navToTreeItem">
<xsl:with-param name="context" select="$new-li"/>
<xsl:with-param name="expand"
select="if ($keyCode eq 39) then true() else false()"/>
</xsl:call-template>
</ixsl:schedule-action>

</xsl:otherwise>
</xsl:choose>
</xsl:if>
</xsl:template>

<xsl:function name="f:getIndexes" as="xs:integer*">
<xsl:param name="li"/>
<xsl:sequence select="$li/@data-id"/>
<xsl:for-each select="$li/../..">
<xsl:sequence select="f:getIndexes(.)"/>
</xsl:for-each>
</xsl:function>

<xsl:template name="show-location">
<xsl:param name="location"/>
<xsl:result-document href="#resultpath" method="replace-content">
<p>
<span class="qname"><xsl:value-of select="$location"/></span>
</p>
</xsl:result-document>
</xsl:template>

<xsl:template name="navToTreeItem">
<xsl:param name="context"/>
<xsl:param name="expand" as="xs:boolean"/>
<xsl:variable name="isSpan" select="name(js:getEventTarget(ixsl:event())) eq 'span'"/>
<xsl:for-each select="$context">
<xsl:variable name="pathParts" select="reverse(f:getpath(.))"/>
<xsl:variable name="location" select="f:location($pathParts)"/>
<xsl:variable name="matchRow" select="js:getMatchingPathIndex(substring($location,2))"/>
<xsl:call-template name="show-location">
<xsl:with-param name="location" select="$location"/>
</xsl:call-template>
<xsl:if test="@class ne 'empty'">
<ixsl:set-attribute name="class"
select="if ($expand) then
    if ($isSpan) then 'open'
    else if (@class eq 'open') then 'closed' else 'open'
else @class"/>
<xsl:if test="@class eq 'closed' and $expand">
<xsl:call-template name="show-elements">
<xsl:with-param name="doc" select="js:getCurrentXmlDom()"/>
<xsl:with-param name="ids" select="$pathParts"/>
<xsl:with-param name="index" select="1"/>
<xsl:with-param name="item" select="$navlist"/>
</xsl:call-template>
</xsl:if>
</xsl:if>
<!--
<xsl:variable name="sequence" select="f:getIndexes(.)" as="xs:integer*"/>
<xsl:sequence select="js:highlightSourceFromTree($sequence)"/>
-->
<!--
<xsl:message>
indexes: <xsl:value-of select="for $a in $sequence return concat('/',string($a))"/>
</xsl:message>
-->
<xsl:call-template name="do-highlight">
<xsl:with-param name="pathParts" select="$pathParts"/>
</xsl:call-template>
<xsl:choose>
<xsl:when test="$matchRow lt 0">
<xsl:call-template name="unhighlight-row-only"/>
</xsl:when>
<xsl:otherwise>
<xsl:for-each select="id('btbody',ixsl:page())/tr[$matchRow + 1]">
<xsl:call-template name="highlight-row"/>
</xsl:for-each>
</xsl:otherwise>
</xsl:choose>
</xsl:for-each>
</xsl:template>

<xsl:template match="li[@class=('open','closed','empty')]" mode="ixsl:onclick">
<xsl:sequence select="js:disableScroll()"/>
<xsl:call-template name="navToTreeItem">
<xsl:with-param name="context" select="."/>
<xsl:with-param name="expand" select="true()"/>
</xsl:call-template>
</xsl:template>

<xsl:template match="div[@id eq 'source']/span" mode="ixsl:onclick">
<xsl:variable name="el-id"
select="if (@id) then @id 
else (preceding-sibling::*[@id])[last()]/@id"/>
<xsl:variable name="start" select="if (substring($el-id, 1, 3) = ('idx','idm')) then 4 else 3" as="xs:integer"/>
<xsl:variable name="id" select="number(substring($el-id, $start))"/>
<xsl:variable name="source-xpath" select="substring(js:getSourcePath($id), 2)"/>
<!--
<xsl:message>source: <xsl:value-of select="$source-xpath"/></xsl:message>
-->
<xsl:value-of select="js:disableTextScroll()"/>
<xsl:call-template name="do-show">
<xsl:with-param name="pathParts" select="tokenize($source-xpath, '/')"/>
</xsl:call-template>

</xsl:template>

<xsl:template name="do-highlight">
<xsl:param name="pathParts" as="xs:string*"/>
<ixsl:schedule-action wait="1">
<xsl:call-template name="highlight-item">
<xsl:with-param name="parent" select="$nav-panel"/>
<xsl:with-param name="ids" select="$pathParts"/>
<xsl:with-param name="index" select="1"/>
</xsl:call-template>
</ixsl:schedule-action>

<ixsl:schedule-action wait="20">
<xsl:call-template name="enableTextScroll"/>
</ixsl:schedule-action>

</xsl:template>

<xsl:template name="do-show">
<xsl:param name="pathParts" as="xs:string*"/>
<xsl:variable name="lastPart" select="$pathParts[last()]"/>
<xsl:variable name="isAttr" select="starts-with($lastPart, '@')"/>
<xsl:variable name="isText" select="starts-with($lastPart, 'text()')"/>
<xsl:variable name="parts" select="if ($isAttr or $isText) then
    subsequence($pathParts, 1, count($pathParts) - 1)
else $pathParts"/>
<xsl:call-template name="show-elements">
<xsl:with-param name="doc" select="js:getCurrentXmlDom()"/>
<xsl:with-param name="ids" select="$parts"/>
<xsl:with-param name="index" select="1"/>
<xsl:with-param name="item" select="$navlist"/>
</xsl:call-template>

<xsl:if test="js:isTextScrollDisabled()">
<xsl:call-template name="show-location">
<xsl:with-param name="location" select="f:location($pathParts)"/>
</xsl:call-template>
</xsl:if>

<xsl:call-template name="do-highlight">
<xsl:with-param name="pathParts" select="$parts"/>
</xsl:call-template>

</xsl:template>

<xsl:template name="enableTextScroll">
<xsl:value-of select="js:enableTextScroll()"/>
</xsl:template>

<xsl:template name="highlight-item">
<xsl:param name="parent" as="node()?"/>
<xsl:param name="ids" as="xs:string*"/>
<xsl:param name="index" as="xs:integer"/>

<xsl:variable name="id" select="f:getIdParts($ids[$index])"/>
<xsl:variable name="name" select="$id[2]"/>
<xsl:variable name="pred" select="$id[1]" as="xs:double"/>

<!--
<xsl:message>
id-highlight <xsl:value-of select="string-join($ids, ' - ')"/>
name <xsl:value-of select="$name"/>
pred <xsl:value-of select="$pred"/>
</xsl:message>
-->

<xsl:variable name="hitem" select="$parent/ul/li[span eq $name][$pred]"/>
<xsl:choose>
<xsl:when test="$index lt count($ids)">
<xsl:call-template name="highlight-item">
<xsl:with-param name="parent" select="$hitem"/>
<xsl:with-param name="ids" select="$ids"/>
<xsl:with-param name="index" select="$index + 1"/>
</xsl:call-template>
</xsl:when>
<xsl:otherwise>
<xsl:variable name="sequence" select="f:getIndexes($hitem)" as="xs:integer*"/>
<xsl:sequence select="js:highlightSourceFromTree($sequence)"/>

<xsl:for-each select="$hitem/span">
<xsl:for-each select="js:swapItem(.)">
<ixsl:set-attribute name="class" select="'item'"/>
</xsl:for-each>
<xsl:sequence select="js:enableScroll()"/>
<ixsl:set-attribute name="class" select="'hot'"/>
</xsl:for-each>
<!--
<xsl:if test="$navlist/../div[@class eq 'found']/@style:display ne 'none'">
<xsl:sequence select="f:highlight-finds()"/>
</xsl:if>
-->
</xsl:otherwise>
</xsl:choose>
</xsl:template>


<xsl:function name="f:location" as="xs:string">
<xsl:param name="parts" as="xs:string*"/>
<xsl:value-of select="concat('/', string-join($parts,'/'))"/>
</xsl:function>

<xsl:function name="f:getpath">
<xsl:param name="node"/>
<xsl:for-each select="$node">
<xsl:variable name="n" select="span"/>
<xsl:variable name="c" select="count(preceding-sibling::*[span eq $n])"/>
<xsl:variable name="fc" select="count(following-sibling::*[span eq $n])"/>
<xsl:value-of select="if ($c gt 0 or $fc gt 0)
then concat($n, '[',$c + 1, ']')
else $n"/>

<xsl:for-each select="$node/ancestor::li[1]">
<xsl:sequence select="f:getpath(.)"/>
</xsl:for-each>
</xsl:for-each>
</xsl:function>

<xsl:template name="show-elements">
<xsl:param name="doc" as="node()"/>
<xsl:param name="ids" as="xs:string*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:param name="item" as="node()?"/>

<xsl:variable name="nextid" select="f:getIdParts($ids[$index + 1])"/>
<xsl:variable name="nextname" select="$nextid[2]"/>
<xsl:variable name="nextpred" select="$nextid[1]" as="xs:double"/>

<xsl:variable name="id" select="f:getIdParts($ids[$index])"/>
<xsl:variable name="name" select="$id[2]"/>
<xsl:variable name="pred" select="$id[1]" as="xs:double"/>

<!--
<xsl:message>
ids: <xsl:value-of select="string-join($ids, ' - ')"/>
item: <xsl:value-of select="$item/span"/>
docnames <xsl:value-of select="$doc/*/name()"/>
******************************
name: <xsl:value-of select="$name"/>
pred: <xsl:value-of select="$pred"/>
******************************
nextname: <xsl:value-of select="$nextname"/>
nextpred: <xsl:value-of select="$nextpred"/>
</xsl:message>

-->

<xsl:for-each select="$item">
<ixsl:set-attribute name="class" select="f:get-open-class(@class)"/>
<!--
<xsl:message>se: <xsl:value-of select="string-join($ids,' - ')"/></xsl:message>
-->
<xsl:choose>
<xsl:when test="not(empty(ul))">
<xsl:if test="$index lt count($ids)">
<xsl:call-template name="show-elements">
<xsl:with-param name="doc" select="$doc/*[name(.) eq $name][$pred]"/>
<xsl:with-param name="ids" select="$ids"/>
<xsl:with-param name="index" select="$index + 1"/>
<xsl:with-param name="item" select="ul/li[span eq $nextname][$nextpred]"/>
</xsl:call-template>


</xsl:if>
</xsl:when>
<xsl:otherwise>
<xsl:result-document href="?select=." method="append-content">
<xsl:call-template name="add-element">
<xsl:with-param name="section" select="$doc/*[name(.) eq $name][$pred]"/>
<xsl:with-param name="ids" select="$ids"/>
<xsl:with-param name="index" select="$index"/>
</xsl:call-template>
</xsl:result-document>
</xsl:otherwise>
</xsl:choose>
</xsl:for-each>

</xsl:template>

<xsl:template name="add-element">
<xsl:param name="section" as="node()"/>
<xsl:param name="ids" as="xs:string*"/>
<xsl:param name="index" as="xs:double"/>

<xsl:variable name="id" select="f:getIdParts($ids[$index + 1])"/>
<xsl:variable name="name" select="$id[2]"/>
<xsl:variable name="pred" select="$id[1]" as="xs:double"/>

<!--
<xsl:message>
ids-ae <xsl:value-of select="string-join($ids, ' - ')"/>
name-ae <xsl:value-of select="$name"/>
pred-ae <xsl:value-of select="$pred"/>
</xsl:message>
-->
<xsl:if test="exists($section/*)">
<xsl:sequence select="js:initPredCount($name, $index)"/>
<ul>
<xsl:for-each select="$section/*">
<xsl:variable name="predCount"
select="if (empty($name)) then 0 else
js:getPredCount(name(.), $index)" as="xs:double"/>

<xsl:variable name="onpath" as="xs:boolean*"
select="$index lt count($ids) and name(.) eq $name and $pred eq $predCount"/>
<xsl:variable name="contains" select="exists(*)"/>
<!--
<xsl:message>onpath: <xsl:value-of select="$onpath"/>
name: <xsl:value-of select="name(.)"/>
predCount: <xsl:value-of select="$predCount"/>
</xsl:message>

-->
<!--
<li id="{$pred}">
-->
<li data-id="{position()}">
<xsl:attribute name="class"
select="if ($onpath and $contains) then 'open'
else if ($contains) then 'closed'
else 'empty'"/>
<span class="item"><xsl:value-of select="name(.)"/></span>
<xsl:if test="$onpath">
<xsl:call-template name="add-element">
<xsl:with-param name="section" select="$section/*[name(.) = $name][$pred]"/>
<xsl:with-param name="ids" select="$ids"/>
<xsl:with-param name="index" select="$index + 1"/>
</xsl:call-template>
</xsl:if>
</li>
</xsl:for-each>
</ul>
</xsl:if>

</xsl:template>

<xsl:function name="f:get-open-class" as="xs:string">
<xsl:param name="class" as="xs:string"/>
<xsl:sequence select="if ($class eq 'empty') then 'empty'
 else 'open'"/>
</xsl:function>





</xsl:transform>
