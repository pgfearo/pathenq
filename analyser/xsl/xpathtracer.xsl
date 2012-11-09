<!-- Copyright Phil Fearon - Qutoric limited 2012 - philipfearon@qutoric.com -->
<xsl:transform
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:style="http://saxonica.com/ns/html-style-property"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:loc="com.qutoric.sketchpath.functions"
exclude-result-prefixes="xs prop"
extension-element-prefixes="ixsl"
version="2.0"
>


<xsl:template name="runReset">
<xsl:for-each select="id('reset', ixsl:page())">
<xsl:value-of select="ixsl:call(.,'blur')"/>
<xsl:sequence select="loc:save-expr()"/>
<xsl:result-document href="#wrapper" method="ixsl:replace-content">
<div id="content" contenteditable="true" spellcheck="false">
<p><span>&#160;</span></p>
</div>
</xsl:result-document>
<xsl:call-template name="switchToEditMode"/>
</xsl:for-each>
</xsl:template>

<xsl:template match="button[@id='reset']" mode="ixsl:onclick">
<xsl:call-template name="runReset"/>
</xsl:template>

<!--
<xsl:template match="div[@id = 'content']" mode="ixsl:onkeydown" ixsl:prevent-default="yes" ixsl:event-property="keyCode 9">
<xsl:message>tab! <xsl:value-of select="ixsl:get(ixsl:event(),'target.id')"/></xsl:message>
</xsl:template>

-->
<xsl:template match="p[@id eq 'xmlurl']" mode="ixsl:onkeydown"
ixsl:event-property="keyCode 13" ixsl:prevent-default="yes">
<xsl:result-document href="#xbody">
<p>Requesting document: <xsl:value-of select="."/> ...</p>
</xsl:result-document>
<xsl:value-of select="js:addFileFromURL(normalize-space(.))"/>
</xsl:template>

<xsl:template match="p[@id eq 'xmlurl']" mode="ixsl:onclick">
<xsl:if test="normalize-space(.) eq 'Enter URL'">
<xsl:result-document href="#xmlurl" method="replace-content">
<xsl:text></xsl:text>
</xsl:result-document>
</xsl:if>
</xsl:template>

<xsl:template match="p[@id='closehelp']" mode="ixsl:onclick">
<xsl:for-each select="..">
<ixsl:set-attribute name="style:display" select="'none'"/>
</xsl:for-each>
</xsl:template>

<xsl:template match="span[@class=('parent','hotparent')]" mode="ixsl:onclick">
<xsl:sequence select="js:removeSpan(., string(span))"/>
</xsl:template>

<xsl:template match="p[@id='closeoptions']" mode="ixsl:onclick">
<xsl:for-each select="..">
<ixsl:set-attribute name="style:display" select="'none'"/>
</xsl:for-each>
</xsl:template>

<xsl:template match="div[@id='options']/ul/li" mode="ixsl:onclick">
<xsl:choose>
<xsl:when test="@id='hidesource'">
<xsl:for-each select="*">
<xsl:variable name="isOn" select=". eq 'On'" as="xs:boolean"/>
<xsl:choose>
<xsl:when test="not($isOn)">
<xsl:sequence select="js:clearXmlSource()"/>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="js:alwaysRenderXml()"/>
</xsl:otherwise>
</xsl:choose>
<xsl:result-document href="?select=." method="replace-content">
<xsl:value-of select="if ($isOn) then 'Off' else 'On'"/>
</xsl:result-document>
</xsl:for-each>
</xsl:when>
<xsl:otherwise>
<xsl:variable name="size" as="xs:integer+"
select="if (@id='size1') then (116, 50)
else if (@id='size2') then (166, 100)
else (466, 400)"/>
<xsl:for-each select="id('results')">
<ixsl:set-attribute name="style:top" select="concat($size[1], 'px')"/>
</xsl:for-each>
<xsl:for-each select="id('wrapper')">
<ixsl:set-attribute name="style:height" select="concat($size[2], 'px')"/>
</xsl:for-each>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:function name="loc:getDisplay">
<xsl:param name="setDisplay" as="xs:boolean"/>
<xsl:value-of select="if ($setDisplay) then 'block' else 'none'"/>
</xsl:function>

<!--
<xsl:template match="p[@id='urlbutton']" mode="ixsl:onclick">
<xsl:variable name="iframe" select="id('web')"/>
<xsl:variable name="iwin" select="ixsl:get($iframe, 'contentWindow')"/>
<xsl:message>if <xsl:value-of select="ixsl:get($iwin, 'document.childNodes.length')"/></xsl:message>
</xsl:template>

<xsl:template name="modpage">
<xsl:variable name="iwin" select="ixsl:get($iframe, 'contentWindow')"/>
<xsl:variable name="doc" select="ixsl:call($iwin,'createDocument')"/>

</xsl:template>

-->
<xsl:template match="p[@class='left']" mode="ixsl:onclick">
<ixsl:set-attribute name="class" select="'lefthot'"/>
<xsl:for-each select="../p[@class='lefthot']">
<ixsl:set-attribute name="class" select="'left'"/>
</xsl:for-each>
<xsl:variable name="showId" select="substring(@id, 3)"/>
<xsl:for-each select="../../div[@id = $showId]">
<ixsl:set-attribute name="style:display" select="'block'"/>
</xsl:for-each>
<xsl:for-each select="../../div[not(@id = ($showId, 'xbar','resultbar'))]">
<ixsl:set-attribute name="style:display" select="'none'"/>
</xsl:for-each>
<xsl:if test="$showId eq 'browser'">
<ixsl:set-property object="id('web')" name="src" select="string(id('urlentry'))"/>
</xsl:if>

<xsl:choose>
<xsl:when test="../@id = 'resultbar'"/>
<xsl:otherwise>
<xsl:variable name="displayAdd" select="loc:getDisplay($showId eq 'xtable')"/>
<xsl:for-each select="../p[. eq 'Add']">
<ixsl:set-attribute name="style:display" select="$displayAdd"/>
</xsl:for-each>
<xsl:variable name="displayClear" select="loc:getDisplay(not($showId eq 'nav'))"/>
<xsl:for-each select="../p[. eq 'Clear']">
<ixsl:set-attribute name="style:display" select="$displayClear"/>
</xsl:for-each>
<xsl:variable name="displayTree" select="loc:getDisplay($showId eq 'nav')"/>
<xsl:for-each select="../p[. = ('Collapse','Use')]">
<ixsl:set-attribute name="style:display" select="$displayTree"/>
</xsl:for-each>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:function name="loc:save-expr">
<xsl:variable name="lastrow" select="id('xtbody', ixsl:page())/tr[last()]/td[1], '0'" as="xs:string*"/>
<xsl:variable name="rownum" select="number($lastrow[1]) + 1"/>
<xsl:variable name="expr" select="loc:get-xpathtext()"/>
<xsl:if test="string-length(normalize-space($expr)) gt 1">
<xsl:result-document href="#xtbody" method="append-content">
<tr data-expr="{$expr}">
<td class="noedit"><xsl:value-of select="$rownum"/></td>
<td><span contenteditable="true" spellcheck="false" class="editCell">
<!--
<xsl:value-of select="concat('expr',$rownum)"/>
-->
</span></td>
<td class="noedit"><xsl:value-of select="substring($expr, 1, 40)"/></td>
</tr>
</xsl:result-document>
</xsl:if>
</xsl:function>

<xsl:template name="evalTreeItem">
<xsl:result-document href="#location" method="ixsl:replace-content">
<p>
<span class="comment">(: Use :) </span>
<span class="qname"><xsl:value-of select="id('resultpath')"/></span>
<span class="filter">/ ( . | * | @*)</span>
</p>
</xsl:result-document>
<xsl:call-template name="switchToEditMode"/>
<ixsl:schedule-action wait="20">
<xsl:call-template name="eval"/>
</ixsl:schedule-action>
</xsl:template>

<xsl:template match="p[@class eq 'right']" mode="ixsl:onclick">
<xsl:choose>
<xsl:when test="../@id = 'resultbar'">
<xsl:if test="@id='showoptions'">
<xsl:for-each select="id('options')">
<ixsl:set-attribute name="style:display" select="'block'"/>
</xsl:for-each>
</xsl:if>
</xsl:when>
<xsl:otherwise>
<xsl:choose>
<xsl:when test="@id = 'addhistory'">
<xsl:sequence select="loc:save-expr()"/>
</xsl:when>
<xsl:when test="@id = 'collapse'">
<xsl:sequence select="js:renderCurrentXmlTree()"/>
</xsl:when>
<xsl:when test=". = 'Use'">
<xsl:call-template name="evalTreeItem"/>
</xsl:when>
<xsl:otherwise>
<xsl:for-each select="if (../p[. = 'Console']/@class = 'lefthot')
then id('xbody') else id('xtbody')">
<xsl:result-document href="?select=." method="replace-content">
<xsl:sequence select="()"/>
</xsl:result-document>
</xsl:for-each>
</xsl:otherwise>
</xsl:choose>

</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="tbody[@id='xtbody']/tr/td[not(span)]" mode="ixsl:onclick">
<xsl:result-document href="#wrapper" method="ixsl:replace-content">
<div id="content" contenteditable="true" spellcheck="false">
<p><span><xsl:analyze-string select="../@data-expr" regex="\n+">
<xsl:matching-substring><br/></xsl:matching-substring>
<xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
</xsl:analyze-string>
</span>
</p>
</div>
</xsl:result-document>
<xsl:call-template name="switchToEditMode"/>
</xsl:template>

<xsl:template match="span[@class = 'editCell']" mode="ixsl:onclick" priority="2"/>

<xsl:template match="span[@class = 'editCell']" mode="ixsl:onkeydown" ixsl:prevent-default="yes" ixsl:event-property="keyCode 13 38 40">
<xsl:variable name="isCursorUp" select="ixsl:get(ixsl:event(),'keyCode') eq 38" as="xs:boolean"/>
<xsl:variable name="navRow" select="if ($isCursorUp)
then ../../preceding-sibling::tr[1]
else ../../following-sibling::tr[1]"/>
<xsl:for-each select="($navRow/td[2]/span)[1]">
<xsl:sequence select="ixsl:call(. , 'focus')"/>
</xsl:for-each>
</xsl:template>

<xsl:template match="tbody[@id = 'btbody']/tr/td" mode="ixsl:onkeydown"
ixsl:prevent-default="yes"
ixsl:event-property="keyCode 38 40">
<xsl:sequence select="loc:navToResultRow()"/>
</xsl:template>

<xsl:function name="loc:navToResultRow">
<xsl:for-each select="js:getHotRow()">
<xsl:variable name="keyCode" select="ixsl:get(ixsl:event(),'keyCode')" as="xs:double"/>
<xsl:variable name="isCursorUp" select="$keyCode eq 38" as="xs:boolean"/>
<xsl:variable name="navRow" select="if ($isCursorUp)
then preceding-sibling::tr[1]
else following-sibling::tr[1]"/>
<xsl:for-each select="$navRow">
<xsl:call-template name="selectResultRow"/>
</xsl:for-each>
</xsl:for-each>
</xsl:function>

<xsl:template match="p[@id = ('nextRow','prevRow')]" mode="ixsl:onclick" priority="2">
<xsl:variable name="cachedRow" select="js:currentRow()"/>
<xsl:variable name="navRow" select="if (empty($cachedRow)) then id('btbody')/tr[1] else
if (@id eq 'prevRow')
then $cachedRow/preceding-sibling::tr[1]
else $cachedRow/following-sibling::tr[1]"/>
<xsl:for-each select="$navRow">
<xsl:call-template name="selectResultRow"/>
</xsl:for-each>
</xsl:template>

<xsl:template match="tbody[@id='btbody']/tr" mode="ixsl:onclick">
<xsl:sequence select="js:disableResultScroll()"/>
<xsl:call-template name="selectResultRow">
<xsl:with-param name="temp-disabled" select="true()"/>
</xsl:call-template>
</xsl:template>

<xsl:template name="selectResultRow">
<xsl:param name="temp-disabled" select="false()" as="xs:boolean"/>
<xsl:call-template name="highlight-row"/>
<xsl:sequence select="if ($temp-disabled) then js:enableResultScroll() else ()"/>
<xsl:variable name="xpath" select="js:getPath(number(td[1]) - 1)"/>
<xsl:result-document href="#resultpath" method="replace-content">
<p><span class="qname"><xsl:value-of select="concat('/', $xpath)"/></span></p>
</xsl:result-document>
<xsl:call-template name="do-show">
<xsl:with-param name="pathParts" select="tokenize($xpath, '/')"/>
</xsl:call-template>
</xsl:template>

<xsl:template name="highlight-row">
<xsl:variable name="oldrow" select="js:swapRow(.)"/>
<xsl:for-each select="if ($oldrow ne .) then $oldrow else ()">
<ixsl:set-attribute name="class" select="'notrow'"/>
</xsl:for-each>
<ixsl:set-attribute name="class" select="'hotrow'"/>
<xsl:result-document href="#result-place" method="replace-content">
<xsl:value-of select="td[1]"/>
</xsl:result-document>
</xsl:template>

<xsl:template name="unhighlight-row-only">
<xsl:variable name="oldrow" select="js:swapRow(())"/>
<xsl:for-each select="$oldrow">
<ixsl:set-attribute name="class" select="'notrow'"/>
</xsl:for-each>
</xsl:template>

<xsl:template match="div[@id='drop_zone']/span/span" mode="ixsl:onclick">
<xsl:if test="not(@id = 'drop')">
<xsl:sequence select="js:handleFileClick(string(.), .)"/>
<xsl:call-template name="switchToEditMode"/>
</xsl:if>
</xsl:template>

<xsl:template name="focusOnEditor">
<ixsl:schedule-action wait="10">
<xsl:call-template name="focusOnEditorNow"/>
</ixsl:schedule-action>
</xsl:template>

<xsl:template name="focusOnEditorNow">
<!-- setting focus not reliable in IE - must use selection
     so set to the Run button -->
<!--
<xsl:for-each select="id('content', ixsl:page())/p[1]/span[1]">
<xsl:value-of select="ixsl:call(., 'focus')"/>
</xsl:for-each>

-->

<xsl:value-of select="ixsl:call(id('trace',ixsl:page()), 'focus')"/>
<!--
<xsl:value-of select="ixsl:call(id('content', ixsl:page()), 'focus')"/>
-->


</xsl:template>

<xsl:template match="button[@id='helpbutton']" mode="ixsl:onclick">
<xsl:for-each select="id('results')">
<xsl:variable name="top" select="if (@style:top) then 
@style:top else '116px'"/>
<ixsl:set-attribute name="style:top"
select="if ($top eq '116px') then '166px'
else if ($top eq '166px') then '466px'
else '116px'"/>
</xsl:for-each>
<xsl:for-each select="id('wrapper')">
<xsl:variable name="ht" select="if (@style:height) then @style:height else '50px'"/>
<ixsl:set-attribute name="style:height"
select="
if ($ht eq '50px') then '100px'
else if ($ht eq '100px') then '400px'
else '50px'"/>
</xsl:for-each>
</xsl:template>

<xsl:template match="node()|@*" mode="escapebutton">
<xsl:copy>
<xsl:apply-templates select="node()|@*" mode="escapebutton"/>
</xsl:copy>
</xsl:template>

<xsl:template match="text()" mode="escapebutton">
<xsl:value-of select="loc:escape(. , false())"/>
</xsl:template>

<xsl:template match="button[@id='escapebutton']" mode="ixsl:onclick">
<xsl:for-each select="ixsl:page()/html/body/div/div[@id eq 'content']">
<xsl:result-document href="?select=." method="replace-content">
<xsl:apply-templates select="ixsl:page()/html/body/div/div[@id eq 'content']/node()" mode="escapebutton"/>
</xsl:result-document>
</xsl:for-each>
</xsl:template>

<xsl:template match="button[@id='edit']" mode="ixsl:onclick">
<xsl:call-template name="runSwitchTrace"/>
</xsl:template>

<xsl:template name="runSwitchTrace">
<xsl:for-each select="id('edit',ixsl:page())">
<xsl:choose>
<xsl:when test="@class='on'">
<xsl:call-template name="switchToEditMode"/>
</xsl:when>
<xsl:otherwise>
<xsl:call-template name="switchTrace">
<xsl:with-param name="editable" select="false()"/>
</xsl:call-template>
</xsl:otherwise>
</xsl:choose>
</xsl:for-each>
</xsl:template>

<xsl:template name="switchToEditMode">
<xsl:call-template name="switchTrace">
<xsl:with-param name="editable" select="true()"/>
</xsl:call-template>
<xsl:call-template name="unhighlight">
<xsl:with-param name="newStart" select="''" as="xs:string"/>
<xsl:with-param name="newGroup" select="()" as="element()*"/>
</xsl:call-template>
<xsl:call-template name="focusOnEditor"/>
</xsl:template>

<xsl:function name="loc:swapCurrentId" as="xs:string">
<xsl:param name="newId" as="xs:string"/>
<xsl:value-of select="ixsl:call(ixsl:window(), 'swapId', $newId)"/>
</xsl:function>

<xsl:function name="loc:getCurrentId" as="xs:string">
<xsl:value-of select="ixsl:call(ixsl:window(), 'getId')"/>
</xsl:function>

<xsl:template match="div[@id='content']" mode="ixsl:onclick">
<xsl:value-of select="js:setIsXPathEditorFocused()"/>
</xsl:template>

<xsl:template match="div[@id='content']/p/span" mode="ixsl:onclick">
<xsl:value-of select="js:setIsXPathEditorFocused()"/>
<xsl:if test="not(../../@contenteditable eq 'true')" >
<xsl:apply-templates select="." mode="highlight"/>
<!-- wait for new path to be updated -->
<ixsl:schedule-action wait="20">
<xsl:call-template name="eval"/>
</ixsl:schedule-action>
</xsl:if>
</xsl:template>

<xsl:template match="*" mode="ixsl:onkeydown">
<xsl:variable name="activeElement" select="ixsl:get(ixsl:page(), 'activeElement')"/>
<xsl:variable name="activeElementName" select="name($activeElement)"/>
<xsl:variable name="activeElementId" select="$activeElement/@id"/>
<xsl:variable name="isCtrlKey" select="ixsl:get(ixsl:event(),'ctrlKey')" as="xs:boolean"/>
<xsl:variable name="keycode" select="ixsl:get(ixsl:event(),'keyCode')" as="xs:double"/>
<xsl:variable name="traceOn" select="id('edit', ixsl:page())/@class eq 'on'" as="xs:boolean"/>

<xsl:choose>
<!-- Issues with 'freezing' in IE - 116:F5  82:R 72:J 78:N 81:Q -->
<xsl:when test="$keycode = 13 and not(js:getIsXPathEditorFocused() and $traceOn)">
<xsl:if test="not(js:getIsXPathEditorFocused())">
<xsl:value-of select="js:preventDefault(ixsl:event())"/>
<xsl:call-template name="evalTreeItem"/>
</xsl:if>
</xsl:when>
<!--
<xsl:when test="$keycode eq 116">
<xsl:value-of select="js:preventDefault(ixsl:event())"/>
<xsl:call-template name="runXPath"/>
</xsl:when>
<xsl:when test="$isCtrlKey">
<xsl:choose>
<xsl:when test="$keycode eq 82">
<xsl:call-template name="runXPath"/>
<xsl:call-template name="focusOnEditor"/>
</xsl:when>
<xsl:when test="$keycode eq 74">
<xsl:call-template name="runSwitchTrace"/>
</xsl:when>
<xsl:when test="$keycode eq 78">
<xsl:value-of select="js:preventDefault(ixsl:event())"/>
</xsl:when>
<xsl:when test="$keycode eq 81">
<xsl:call-template name="runReset"/>
</xsl:when>
</xsl:choose>
<xsl:message>is control <xsl:value-of select="$keycode"/></xsl:message>
</xsl:when>
-->

<xsl:when test="$traceOn and js:getIsXPathEditorFocused()">
<!-- Get the element that we've just come from -->

<xsl:variable name="scanId" select="loc:getCurrentId()"/>
<xsl:variable name="scanElement" select="ixsl:page()//div[@id='content']/p/span[@start = $scanId]" as="element()?"/>

<!--
<xsl:variable name="event" select="ixsl:event()"/>
-->

<xsl:if test="not(empty($scanElement))">
<!-- Get new elment that keydown must cause us to move to -->
<xsl:variable name="newElement" as="element()?">
<xsl:variable name="elements" select="$scanElement//span[@select]"/>
<xsl:choose>
<xsl:when test="$keycode eq 37">
<xsl:variable name="previous" select="$scanElement/preceding-sibling::*[@select][1]"/>
<xsl:choose>
<xsl:when test="empty($previous)">
<xsl:sequence select="$scanElement/parent::*/preceding-sibling::*[1]/child::*[@select][position() = last()]"/>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="$previous"/>
</xsl:otherwise>
</xsl:choose>
</xsl:when>
<xsl:when test="$keycode eq 38">
<xsl:sequence select="$scanElement/parent::*/preceding-sibling::*[1]/child::*[@select][1]"/>
</xsl:when>
<xsl:when test="$keycode eq 39">
<xsl:variable name="following" select="$scanElement/following-sibling::*[@select][1]"/>
<xsl:choose>
<xsl:when test="empty($following)">
<xsl:sequence select="$scanElement/parent::*/following-sibling::*[1]/child::*[@select][1]"/>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="$following"/>
</xsl:otherwise>
</xsl:choose>
</xsl:when>
<xsl:when test="$keycode eq 40">
<xsl:sequence select="$scanElement/parent::*/following-sibling::*[1]/child::*[@select][1]"/>
</xsl:when>
</xsl:choose>
</xsl:variable>

<xsl:choose>
<xsl:when test="$keycode eq 13">
<xsl:value-of select="js:preventDefault(ixsl:event())"/>

<ixsl:schedule-action wait="20">
<xsl:call-template name="eval"/>
</ixsl:schedule-action>
</xsl:when>
<xsl:otherwise>
<ixsl:schedule-action wait="16">
<xsl:call-template name="deferredHighlight">
<xsl:with-param name="context" select="$newElement"/>
</xsl:call-template>
</ixsl:schedule-action>
</xsl:otherwise>
</xsl:choose>

</xsl:if>

</xsl:when>

<xsl:when test="$activeElementName eq 'body' and js:getIsResultsFocused()">
<xsl:sequence select="loc:navToResultRow()"/>
</xsl:when>

<xsl:when test="$activeElementId = ('nav','trace') or
($activeElementName eq 'body' and not(js:getIsResultsFocused()))">
<!--
<xsl:message>navto tree
is results focused <xsl:value-of select="js:getIsResultsFocused()"/>
</xsl:message>
-->
<xsl:call-template name="navToNewTreeItem"/>
</xsl:when>


<xsl:otherwise>
<!-- allow keyboard nav of editable content -->
<!--
<xsl:message>nav to nothing
activeElementName <xsl:value-of select="$activeElementName"/>
activeId <xsl:value-of select="$activeElementId"/>
is results focused <xsl:value-of select="js:getIsResultsFocused()"/>
</xsl:message>

-->
</xsl:otherwise>

</xsl:choose>

</xsl:template>

<xsl:template name="deferredHighlight">
<xsl:param name="context"/>
<xsl:apply-templates select="$context" mode="highlight"/>
</xsl:template>

<xsl:template name="resolvePaths">
<xsl:param name="highlightGroup" as="element()*"/>
<xsl:param name="context" as="element()?"/>
<xsl:for-each select="$context">

<xsl:variable name="paths" as="element()*">
<xsl:if test="not(@class = ('literal','comment', 'variable'))">
<xsl:variable name="prevSpans" as="element()*"
select=". union ./preceding-sibling::*
union ./parent::*/preceding-sibling::*/child::*"/>

<xsl:call-template name="buildPath">
<xsl:with-param name="spans" select="$prevSpans"/>
<xsl:with-param name="index" select="count($prevSpans)"/>
<xsl:with-param name="prevSpan" select="()"/>
<xsl:with-param name="prevWS" select="false()"/>
<xsl:with-param name="includeToPos" select="'-1'"/>
<xsl:with-param name="findOpenPredPos" select="-1" as="xs:integer"/>
</xsl:call-template>
</xsl:if>
</xsl:variable>

<xsl:result-document href="#location" method="replace-content">
<p>
<xsl:choose>
<xsl:when test="@class='variable'">
<xsl:variable name="resolved" as="element()*">
<xsl:apply-templates select="loc:resolveVariable(.)" mode="strip-back"/>
</xsl:variable>
<xsl:choose>
<xsl:when test="exists($resolved)">
<xsl:sequence select="$resolved"/>
</xsl:when>
<xsl:otherwise>
<xsl:copy-of select="."/>
<span class="qname"> could not be resolved.</span>
</xsl:otherwise>
</xsl:choose>
</xsl:when>
<xsl:when test="exists($paths)">
<xsl:apply-templates select="loc:resolveSequence(reverse($paths), 1)" mode="strip-back"/>
<xsl:if test="count($highlightGroup) gt 1">
<xsl:apply-templates select="loc:resolveSequence(subsequence($highlightGroup, 2), 1)" mode="strip-back"/>
</xsl:if>
<xsl:if test="@class eq 'axis'">
<span class="node"><xsl:value-of select="if (. = ('attribute::','@')) then '*' else 'node()'"/></span>
</xsl:if>
</xsl:when>
<xsl:otherwise>
<span class="none">No result</span>
</xsl:otherwise>
</xsl:choose>
</p>
</xsl:result-document>
</xsl:for-each>

</xsl:template>

<xsl:function name="loc:resolveVarPath" as="element()*">
<xsl:param name="context" as="element()?"/>

<xsl:for-each select="$context">
<xsl:variable name="paths" as="element()*">
<xsl:if test="not(@class = ('literal','comment', 'variable'))">
<xsl:variable name="prevSpans" as="element()*"
select=". union ./preceding-sibling::*
union ./parent::*/preceding-sibling::*/child::*"/>

<xsl:call-template name="buildPath">
<xsl:with-param name="spans" select="$prevSpans"/>
<xsl:with-param name="index" select="count($prevSpans)"/>
<xsl:with-param name="prevSpan" select="()"/>
<xsl:with-param name="prevWS" select="false()"/>
<xsl:with-param name="includeToPos" select="'-1'"/>
<xsl:with-param name="findOpenPredPos" select="-1" as="xs:integer"/>
</xsl:call-template>
</xsl:if>
</xsl:variable>
<!-- resolve any variables in the absolute path added -->
<xsl:sequence select="loc:resolveSequence(reverse($paths), 1)"/>
</xsl:for-each>

</xsl:function>


<xsl:function name="loc:scanVarExpression" as="element()*">
<xsl:param name="context" as="element()*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:param name="prevToken" as="element()?"/>
<!-- if within a predicate -->
<xsl:param name="skipToClose" as="xs:integer"/>

<xsl:variable name="token" select="$context[$index]" as="element()?"/>
<xsl:variable name="class" select="$token/@class" as="xs:string"/>
<xsl:choose>
<xsl:when test="$skipToClose gt -1">
<xsl:sequence select="$token"/>
</xsl:when>
<xsl:when test="$class = ('qname','axis','node', 'function') and 
not($prevToken/@class = ('step', 'predicate','axis'))">
<xsl:sequence select="loc:resolveVarPath($token)"/>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="$token"/>
</xsl:otherwise>
</xsl:choose>
<xsl:if test="$index + 1 le count($context)">
<xsl:variable name="newPrevToken" as="element()?"
select="if ($class eq 'whitespace') then $prevToken else $token"/>
<xsl:variable name="newSkipToClose" as="xs:integer">
<xsl:choose>
<xsl:when test="$skipToClose gt -1">
<xsl:value-of select="if (number($token/@start) eq $skipToClose) 
then -1 else $skipToClose"/>
</xsl:when>
<xsl:when test="$token/@pair-end and number($token/@pair-end) ne -1">
<xsl:value-of select="$token/@pair-end"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="-1"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:sequence select="loc:scanVarExpression($context, $index + 1, $newPrevToken, $newSkipToClose)"/>
</xsl:if>
</xsl:function>


<xsl:template match="*" mode="highlight">
<xsl:variable name="highlightGroup" select="loc:getRange(.)" as="element()*"/>

<xsl:for-each select="$highlightGroup">
<ixsl:set-attribute name="style" select="'backgroundColor: #106010'"/>
</xsl:for-each>

<xsl:call-template name="unhighlight">
<xsl:with-param name="newStart" select="@start" as="xs:string"/>
<xsl:with-param name="newGroup" select="$highlightGroup" as="element()*"/>
</xsl:call-template>

<xsl:call-template name="resolvePaths">
<xsl:with-param name="highlightGroup" select="$highlightGroup"/>
<xsl:with-param name="context" select="."/>
</xsl:call-template>

</xsl:template>

<xsl:template match="*" mode="strip-back">
<xsl:copy>
<xsl:apply-templates select="@*[name() eq 'class']|node()" mode="copynodes"/>
</xsl:copy>
</xsl:template>

<xsl:template match="@*|node()" mode="copynodes">
<xsl:copy/>
</xsl:template>

<xsl:template name="unhighlight">
<xsl:param name="newStart" as="xs:string"/>
<xsl:param name="newGroup" as="element()*"/>

<!--  unhighlight previous, provided it wasn't highlighted just now -->
<xsl:variable name="startId" select="loc:swapCurrentId($newStart)"/>
<xsl:if test="exists($startId)">
<xsl:variable name="div" select="//div[@id='content']" as="element()"/>
<xsl:variable name="prevElement" select="$div//span[@start eq $startId]" as="element()?"/>
<xsl:variable name="prevGroup" select="loc:getRange($prevElement)" as="element()*"/>

<xsl:for-each select="$prevGroup[not(@start = $newGroup/@start)]">
<ixsl:set-attribute name="style:backgroundColor" select="$bgColor"/>
</xsl:for-each>
</xsl:if>
</xsl:template>

<xsl:function name="loc:getRange" as="element()*">
<xsl:param name="first" as="element()?"/>
<xsl:choose>
<xsl:when test="$first/@pair-end">
<xsl:variable name="start" select="number($first/@start)" as="xs:double"/>
<xsl:variable name="end" select="number($first/@pair-end)" as="xs:double"/>
<xsl:sequence select="ixsl:page()//div[@id='content']/p/span
[number(@start) ge $start
and number(@start) le $end]"/>

</xsl:when>
<xsl:otherwise>
<xsl:sequence select="$first"/>
</xsl:otherwise>
</xsl:choose>
</xsl:function>


<!-- //////////////////////////////////////////////////////////////////////////////////////////////// -->


<xsl:function name="loc:resolveVariable" as="element()*">
<!-- param could be a variable reference or the variable declaration -->
<xsl:param name="refSpan" as="element()"/>

<xsl:variable name="fnSpan" as="element()?">
<xsl:choose>
<xsl:when test="$refSpan/@id">
<xsl:sequence select="$refSpan"/>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="id(concat('rng-',$refSpan),$refSpan/../..)"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>
<!-- $fn WS in WS foo... ('return',',') -->
<xsl:choose>
<xsl:when test="exists($fnSpan)">
<xsl:variable name="fnTokens" select="($fnSpan/following-sibling::*
union $fnSpan/parent::node()/following-sibling::*/*)"/>
<xsl:variable name="spans" select="loc:getVariable($fnTokens, 4)" as="element()*"/>
<!-- resolve variable, then resolve relative paths within variable expression, which possible calls resolveVariable... -->

<!--
<xsl:message>
fnSpan <xsl:value-of select="$fnSpan"/>
spans <xsl:value-of select="$spans[1]"/>
resolveSequence <xsl:value-of select="loc:resolveSequence($spans,1)"/>
</xsl:message>
-->

<xsl:sequence select="loc:scanVarExpression(loc:resolveSequence($spans,1), 1, (), -1)"/>

</xsl:when>
<xsl:otherwise>
<span class="unclosed"><xsl:value-of select="$refSpan"/></span>
</xsl:otherwise>
</xsl:choose>
</xsl:function>

<xsl:function name="loc:resolveSequence" as="element()*">
<xsl:param name="spans" as="element()*"/>
<xsl:param name="index" as="xs:integer"/>

<xsl:variable name="span" as="element()?" select="$spans[$index]"/>
<xsl:choose>
<xsl:when test="not($span/@id) and $span/@class eq 'variable'">
<xsl:choose>
<xsl:when test="empty($spans[@id eq concat('rng-',$span)])">
<xsl:sequence select="loc:resolveVariable($span)"/>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="$span"/>
</xsl:otherwise>
</xsl:choose>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="$span"/>
</xsl:otherwise>
</xsl:choose>
<xsl:if test="$index lt count($spans)">
<xsl:sequence select="loc:resolveSequence($spans, $index + 1)"/>
</xsl:if>
</xsl:function>

<xsl:function name="loc:getVariable" as="element()*">
<xsl:param name="fnTokens" as="element()*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:variable name="fnToken" as="element()?" select="$fnTokens[$index]"/>

<xsl:variable name="output" as="element()*">
<xsl:choose>
<xsl:when test="$fnToken = (',','return', 'satisfies')"/>
<xsl:when test="$fnToken/@pair-end">
<xsl:sequence select="$fnTokens[position() ge $index
and number(@start) le number($fnToken/@pair-end)]"/>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="$fnToken"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:choose>
<xsl:when test="empty($output)"/>
<xsl:otherwise>
<xsl:sequence select="$output"/>
<xsl:sequence select="loc:getVariable($fnTokens, $index + count($output))"/>
</xsl:otherwise>
</xsl:choose>

</xsl:function>

<xsl:template name="buildPath" as="element()*">
<xsl:param name="spans" as="element()*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:param name="prevSpan" as="element()?"/>
<xsl:param name="prevWS" as="xs:boolean"/>
<xsl:param name="includeToPos" as="xs:string"/>
<!-- predPos is looking for nested predicated or functions -->
<xsl:param name="findOpenPredPos" as="xs:integer"/>

<xsl:for-each select="$spans[$index]">
<xsl:variable name="prevClass" select="$prevSpan/@class"/>
<xsl:variable name="class" select="@class"/>

<!--
<xsl:message>#3 Class: <xsl:value-of select="$class"/> Text: <xsl:value-of select="."/>
//////////////////////////////
In includeToPos: <xsl:value-of select="$includeToPos"/>
</xsl:message>

-->
<xsl:variable name="output" as="element()?">
<xsl:choose>
<xsl:when test="$findOpenPredPos > -1">
<!--
<xsl:message>
Finding open pred...value is: <xsl:value-of select="."/>
Current close is: <xsl:value-of select="@pair-end"/>
</xsl:message>
-->
<xsl:choose>
<xsl:when test=". eq '[' and (not(@pair-end) or number(@pair-end) gt $findOpenPredPos)
or . eq '/' and $prevClass eq 'function'">
<span class="step">/</span>
</xsl:when>
<!-- create dummy output if nested within a function or open bracket -->
<xsl:when test="$class = 'function' or . eq '(' and number(@pair-end) gt $findOpenPredPos">
<span class="function">dummy</span>
</xsl:when>
</xsl:choose>
</xsl:when>
<xsl:when test="$includeToPos ne '-1'">
<xsl:sequence select="."/>
</xsl:when>
<xsl:when test="empty($prevClass)">
<xsl:choose>
<xsl:when test="$class = ('qname', 'function', 'axis','variable','node') or . = ('[','(')">
<xsl:sequence select="."/>
</xsl:when>
</xsl:choose>
</xsl:when>
<xsl:when test="$prevClass = ('qname', 'node', 'axis', 'function','context') or $prevSpan eq '(' or ($prevSpan eq '*' and $prevClass eq 'quantifier')">
<!-- axis not expected before axis or function - but still ok cos it shouldn't be there -->
<xsl:choose>
<xsl:when test="$class = ('step', 'axis')">
<xsl:sequence select="."/>
</xsl:when>
<!-- convert open predicate into a step -->
<xsl:when test=". = ('[','/')">
<span class="step">/</span>
</xsl:when>
<xsl:when test="$class = 'function' or . eq '('">
<span class="function">dummy</span>
</xsl:when>
</xsl:choose>
</xsl:when>
<xsl:when test="$prevSpan = ('[','/','//')">
<xsl:choose>
<xsl:when test="$class = ('qname','context', 'variable') or . = (')',']')">
<xsl:sequence select="."/>
</xsl:when>
<xsl:when test="$class eq 'quantifier' and . eq '*'">
<xsl:sequence select="."/>
</xsl:when>
</xsl:choose>
</xsl:when>
</xsl:choose>
</xsl:variable>

<xsl:variable name="realoutput" select="exists($output) and not($output eq 'dummy')" as="xs:boolean"/>

<xsl:if test="$realoutput">
<xsl:if test="$prevWS and $includeToPos eq '-1'">
<span class="whitespace">&#160;</span>
</xsl:if>
<xsl:sequence select="$output"/>
</xsl:if>

<xsl:variable name="outFindOpenPredPos"
as="xs:integer"
select="if ($realoutput or ($findOpenPredPos eq -1 and $class='whitespace')) then -1 
else if ($findOpenPredPos > -1) then $findOpenPredPos 
else xs:integer(@start)"/>

<!--
<xsl:message>
in open pred pos: <xsl:value-of select="$findOpenPredPos"/>
out open pred pos: <xsl:value-of select="$outFindOpenPredPos"/>
</xsl:message>

-->
<xsl:variable name="outIncludeToPos" as="xs:string">
<xsl:choose>
<xsl:when test="$includeToPos eq @pair-end">
<!--
<xsl:message>Closed includeToPos on match</xsl:message>
-->
<xsl:value-of select="'-1'"/>
</xsl:when>
<xsl:when test="$includeToPos ne '-1'">
<xsl:value-of select="$includeToPos"/>
</xsl:when>
<xsl:when test="exists($output) and . = (')',']')">
<!--
<xsl:message>Found include ) ] chars</xsl:message>
-->
<xsl:value-of select="@start"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="'-1'"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<!--
<xsl:message>Out Include to Pos: <xsl:value-of select="$outIncludeToPos"/></xsl:message>
-->
<xsl:variable name="outPrevWS" select="@class eq 'whitespace'" as="xs:boolean"/>

<xsl:variable name="reachedAbsoluteStart" as="xs:boolean"
select="$includeToPos eq '-1'
and not($findOpenPredPos gt -1)
and (($prevSpan/@class eq 'step'
and empty($output)
and not($outPrevWS))
or ($class eq 'variable'))"/>

<xsl:if test="not($reachedAbsoluteStart)">
<xsl:call-template name="buildPath">
<xsl:with-param name="spans" select="$spans"/>
<xsl:with-param name="index" select="$index - 1"/>
<!-- never output whitespace as the previous span, use item before whitespace instead -->
<xsl:with-param name="prevSpan" select="if ($outPrevWS) then $prevSpan else ."/>
<xsl:with-param name="prevWS" select="$outPrevWS"/>
<xsl:with-param name="includeToPos" select="$outIncludeToPos"/>
<xsl:with-param name="findOpenPredPos" select="$outFindOpenPredPos" as="xs:integer"/>
</xsl:call-template>
</xsl:if>
</xsl:for-each>
</xsl:template>

</xsl:transform>
