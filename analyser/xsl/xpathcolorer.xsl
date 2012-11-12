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
<xsl:include href="xpathtracer.xsl"/>
<xsl:include href="petree.xsl"/>

<xsl:variable name="ops" select="', / = &lt; &gt; + - * ? | != &lt;= &gt;= &lt;&lt; &gt;&gt; //'"/>
<xsl:variable name="aOps" select="'or and eq ne lt le gt ge is to div idiv mod union intersect except in return satisfies then else'"/>
<xsl:variable name="hOps" select="'for some every'"/>
<xsl:variable name="nodes" select="'attribute comment document-node element node processing-instruction text'"/>
<xsl:variable name="types" select="'empty item node schema-attribute schema-element type'"/>

<xsl:variable name="ambiguousOps" select="tokenize($aOps,'\s+')" as="xs:string*"/>
<xsl:variable name="simpleOps" select="tokenize($ops,'\s+')" as="xs:string*"/>
<xsl:variable name="nodeTests" select="tokenize($nodes,'\s+')" as="xs:string*"/>
<xsl:variable name="typeTests" select="tokenize($types,'\s+')" as="xs:string*"/>
<xsl:variable name="higherOps" select="tokenize($hOps,'\s+')" as="xs:string*"/>
<xsl:variable name="pageRoot" select="ixsl:page()" as="document-node()"/>
<xsl:variable name="bgColor" select="'black'" as="xs:string"/>

<xsl:template name="main">
<xsl:result-document href="#xbody" method="replace-content">
<p>Ready</p>
</xsl:result-document>
</xsl:template>

<xsl:function name="loc:unescape">
<xsl:param name="text"/>
<xsl:analyze-string regex="&amp;#?(\w|\d)+?;" select="$text">
<xsl:matching-substring>
<xsl:variable name="precolon" select="substring(., 1, string-length(.) - 1)"/>
<xsl:value-of select="if (substring(.,1, 3) eq '&amp;#x') then
codepoints-to-string(xs:integer(js:hexToDecimal(substring($precolon, 4))))
else if (substring(.,1,2) eq '&amp;#') then
 codepoints-to-string(xs:integer(substring($precolon, 3)))
 else if (. eq '&amp;amp;') then '&amp;'
else if (. eq '&amp;lt;') then '&lt;'
else if (. eq '&amp;gt;') then '&gt;'
else if (. eq '&amp;quot;') then '&quot;'
else if (. eq '&amp;apos;') then '&apos;&apos;'
else ''
"/>
</xsl:matching-substring>
<xsl:non-matching-substring>
<xsl:value-of select="."/>
</xsl:non-matching-substring>
</xsl:analyze-string>
</xsl:function>

<xsl:function name="loc:escape">
<xsl:param name="text"/>
<xsl:param name="doapos" as="xs:boolean"/>
<xsl:analyze-string regex="[&amp;&lt;&gt;&quot;&apos;]" select="$text">
<xsl:matching-substring>
<xsl:variable name="precolon" select="substring(., 1, string-length(.) - 1)"/>
<xsl:value-of select="if (. eq '&amp;') then
'&amp;amp;'
else if (. eq '&lt;') then
'&amp;lt;'
else if (. eq '&gt;') then
'&amp;gt;'
else if (. eq '&quot;') then
'&amp;quot;'
else if (. eq '&apos;&apos;') then
(if ($doapos) then '&amp;apos;' else .)
else ''
"/>
</xsl:matching-substring>
<xsl:non-matching-substring>
<xsl:value-of select="."/>
</xsl:non-matching-substring>
</xsl:analyze-string>
</xsl:function>

<!-- xsl:v Event handler for button click -->
<xsl:template match="text()" mode="removeBr">
<xsl:value-of select="string-join(loc:unescape(.),'')"/>
</xsl:template>

<xsl:template match="br" mode="removeBr">
<xsl:text>&#10;</xsl:text>
</xsl:template>
<xsl:template match="p" mode="removeBr">
<xsl:apply-templates select="node()" mode="removeBr"/>
<xsl:if test="count(node()) gt 0">
<xsl:text>&#10;</xsl:text>
</xsl:if>
</xsl:template>

<xsl:template name="eval">
<xsl:param name="expr" select="string(id('location', ixsl:page()))"/>
<!-- instead of /top/wrap/*, use /*/*/* to prevent issue with default namespace -->
<xsl:variable name="result"
select="js:eval(string-join(loc:escape($expr, true()),''))/*/*/*"/>
<xsl:result-document href="#btbody" method="replace-content">
<xsl:if test="exists($result)">
<xsl:apply-templates select="$result"/>
<!-- to keep js variable, append dummy -->
<xsl:variable name="paths" as="xs:string*" select="$result/@path, 'xx'"/>
<xsl:sequence select="js:setPaths($paths)"/>
</xsl:if>
</xsl:result-document>
<xsl:sequence select="js:resetCurrentRow()"/>
<xsl:result-document href="#result-count" method="replace-content">
<xsl:value-of select="if (exists($result)) then count($result) else 0"/>
</xsl:result-document>
<xsl:result-document href="#result-place" method="replace-content">
<xsl:text>0</xsl:text>
</xsl:result-document>
</xsl:template>

<xsl:template match="result">
<tr><td><xsl:value-of select="position()"/></td>
<td><xsl:value-of select="@type"/></td>
<td><xsl:value-of select="@name"/></td>
<td><xsl:value-of select="."/></td>
</tr>
</xsl:template>

<xsl:function name="loc:get-xpathtext" as="xs:string?">
<xsl:variable name="xpath-box" select="id('content', ixsl:page())"/>
<xsl:variable name="preChunk" select="if (not(empty($xpath-box))) then $xpath-box else 'Please enter XPath'"/>

<xsl:variable name="qChunk" as="xs:string*">
<xsl:apply-templates select="$preChunk" mode="removeBr"/>
</xsl:variable>
<xsl:variable name="rChunk" select="string-join($qChunk,'')" as="xs:string"/>
<xsl:variable name="pChunk" select="replace($rChunk,'^\n|\n$','')"/>

<xsl:sequence select="if ($pChunk eq '') then ' ' else $pChunk"/>

</xsl:function>

<xsl:template match="button[@id='trace']" mode="ixsl:onclick">
<xsl:call-template name="runXPath"/>
</xsl:template>

<xsl:template name="runXPath">
<xsl:variable name="chunk" select="loc:get-xpathtext()"/>

<xsl:variable name="chars" as="xs:string*"
select="loc:stringToCharSequence($chunk)"/>

<xsl:variable name="awaiting" select="if (matches($chunk,'&lt;/|/&gt;|&lt;xsl:')) then '&quot;' else ''" as="xs:string"/>
<xsl:variable name="a" select="if ($awaiting eq '') then 0 else 1" as="xs:integer"/>

<xsl:variable name="blocks" as="element()*">
<xsl:sequence select="loc:createBlocks($chars, false(), 1, $awaiting, $a, 0)"/>
</xsl:variable>
<xsl:variable name="pbPairs" as="element()*"
select="loc:createPairs($blocks[name() = 'block' and @type = ('[',']','(',')')])"/>

<xsl:variable name="omitPairs" as="element()*"
select="($blocks[name() = ('literal','comment')])"/>

<xsl:variable name="tokens" as="element()*">
<xsl:sequence select="loc:getTokens($chunk, $omitPairs, $pbPairs)"/>
</xsl:variable>

<xsl:result-document href="#wrapper" method="ixsl:replace-content">
<div id="content">
<!-- if trace mode button says 'off' then make editable -->
<xsl:if test="id('edit',ixsl:page())/@class='off'">
<xsl:attribute name="contenteditable" select="'true'"/>
<xsl:attribute name="spellcheck" select="'false'"/>
</xsl:if>
<xsl:sequence select="loc:createTokenParas($tokens, loc:getLineTokens($tokens), 1)"/>
</div>
</xsl:result-document>

<!--
<xsl:result-document href="#xlist" method="replace-content">
<ul>
<xsl:for-each select="$tokens">
<xsl:if test="not(@type eq 'whitespace')">
<li>
<xsl:value-of select="@value, ' '"/>
<span style="color:#8aaaca"><xsl:value-of select="@type"/></span>
</li>
</xsl:if>
</xsl:for-each>
</ul>
</xsl:result-document>

-->

<!--
<xsl:if test="contains(base-uri(ixsl:page()), 'logLevel')">
<xsl:message>
<xsl:text>
</xsl:text>
<xsl:value-of select="concat(loc:pad('Value',31),loc:pad('Start',7),loc:pad('End',7),loc:pad('Type',16),loc:pad('Close',7),loc:pad('Level',7))"/>
<xsl:text>&#10;</xsl:text>
<xsl:for-each select="$tokens">
<xsl:value-of select="loc:pad(concat('{',@value,'}'),30)"/>
<xsl:value-of select="loc:pad(@start, 6)"/>
<xsl:value-of select="loc:pad(@end, 6)"/>
<xsl:value-of select="loc:pad(@type, 15)"/>
<xsl:value-of select="loc:pad(@pair-end, 6)"/>
<xsl:value-of select="loc:pad(@level, 6)"/>
<xsl:text>&#10;</xsl:text>
</xsl:for-each>
</xsl:message>
</xsl:if>
-->

<!--
<xsl:call-template name="switchTrace">
<xsl:with-param name="editable" select="false()"/>
</xsl:call-template>
<xsl:variable name="el" as="element()" select="$pageRoot//button[@id='reset']"/>
<xsl:value-of select="ixsl:call($el,'focus')"/>
-->

<xsl:result-document href="#btbody" method="replace-content">
<xsl:sequence select="''"/>
</xsl:result-document>

<ixsl:schedule-action wait="1">
<xsl:call-template name="eval">
<xsl:with-param name="expr" select="$chunk"/>
</xsl:call-template>
</ixsl:schedule-action>

</xsl:template>

<xsl:template name="switchTrace">
<xsl:param name="editable" as="xs:boolean"/>
<xsl:for-each select="id('edit', ixsl:page())">
<ixsl:set-attribute name="class" select="if ($editable) then 'off' else 'on'"/>
</xsl:for-each>
<xsl:call-template name="editable">
<xsl:with-param name="set" select="$editable" as="xs:boolean"/>
</xsl:call-template>
</xsl:template>

<xsl:template match="*" mode="disable">
<xsl:param name="set" as="xs:boolean" select="true()"/>
<xsl:choose>
<xsl:when test="$set">
<ixsl:remove-attribute name="disabled" namespace=""/>
</xsl:when>
<xsl:otherwise>
<ixsl:set-attribute name="disabled" select="'disabled'"/>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template name="editable">
<xsl:param name="set" as="xs:boolean" select="true()"/>
<xsl:for-each select="id('content', ixsl:page())">
<xsl:choose>
<xsl:when test="not($set)">
<ixsl:remove-attribute name="contenteditable"/>
</xsl:when>
<xsl:otherwise>
<ixsl:set-attribute name="contenteditable" select="'true'"/>
<ixsl:set-attribute name="spellcheck" select="'false'"/>
</xsl:otherwise>
</xsl:choose>
</xsl:for-each>
</xsl:template>

<!-- //////////////////////////////////////////////////////////////////////////////////////////////// -->

<!-- 
 Sample output:
<block position="3" type="["/>
<literal type="'" start="54" end="61"/>
<comment start="65" end="69"/>
<comment start="76"/> // if not closed
 -->

<xsl:function name="loc:pad" as="xs:string">
<xsl:param name="padStringIn" as="xs:string?"/>
<xsl:param name="fixedWidth" as="xs:integer"/>
<xsl:variable name="padString" as="xs:string" select="replace($padStringIn, '\n','\\n')"/>
<xsl:variable name="stringLength" as="xs:integer" select="string-length($padString)"/>
<xsl:variable name="padChar" select="if ($fixedWidth gt 20) then '.' else ' '"/>
<xsl:variable name="padCount" as="xs:integer" select="$fixedWidth - $stringLength"/>
<xsl:if test="$padCount ge 0">
<xsl:sequence select="concat($padString, string-join(for $i in 1 to $padCount 
            return $padChar,''))"/>
</xsl:if>
<xsl:if test="$padCount lt 0">
<xsl:sequence select="concat($padString, '&#10;',' ', string-join(for $i in 1 to $fixedWidth 
            return $padChar,''))"/>
</xsl:if>
</xsl:function>

<xsl:function name="loc:getLineTokens" as="element()*">
<xsl:param name="tokens"/>
<xsl:sequence select="$tokens[@type=('whitespace') and contains(@value, '&#10;')]"/>
</xsl:function>

<xsl:function name="loc:createTokenParas" as="element()*">
<xsl:param name="tokens" as="element()*"/>
<xsl:param name="lineTokens" as="element()*"/>
<xsl:param name="lineIndex" as="xs:integer"/>

<xsl:variable name="cLine" select="$lineTokens[$lineIndex]/@start" as="xs:integer?"/>
<xsl:variable name="pLine" select="$lineTokens[$lineIndex -1]/@start" as="xs:integer?"/>

<xsl:choose>
<xsl:when test="empty($cLine) and empty($pLine)">
<!-- <p>only</p>-->
<p>
<xsl:call-template name="plain">
<xsl:with-param name="para" select="$tokens"/>
</xsl:call-template>
</p>
</xsl:when>
<xsl:when test="empty($pLine) and not(empty($cLine))">
<!--<p>first</p>-->
<p>
<xsl:call-template name="plain">
<xsl:with-param name="para" select="$tokens[number(@start) lt $cLine]"/>
</xsl:call-template>
</p>
</xsl:when>
<xsl:when test="empty($cLine) and not(empty($pLine))">
<!-- <p>final//////////</p>-->
<p><xsl:apply-templates select="$lineTokens[$lineIndex -1]" mode="plainLine"/>
<xsl:call-template name="plain">
<xsl:with-param name="para" select="$tokens[number(@start) gt $pLine]"/>
</xsl:call-template>
</p>
</xsl:when>
<xsl:otherwise>
<p><xsl:apply-templates select="$lineTokens[$lineIndex -1]" mode="plainLine"/>
<xsl:call-template name="plain">
<xsl:with-param name="para" select="$tokens[number(@start) lt $cLine and number(@start) gt $pLine]"/>
</xsl:call-template>

</p>
</xsl:otherwise>
</xsl:choose>

<xsl:if test="$lineIndex le count($lineTokens)">
<xsl:sequence select="loc:createTokenParas($tokens, $lineTokens, $lineIndex + 1)"/>
</xsl:if>
</xsl:function>

<xsl:template name="plain">
<xsl:param name="para" as="element()*"/>

<xsl:variable name="total" select="count($para)" as="xs:integer"/>
<xsl:for-each select="1 to $total">
<xsl:variable name="index" select="."/>
<xsl:for-each select="$para[$index]">
<span>
<xsl:if test="@type eq 'variable' and $index + 2 lt $total">
<xsl:if test="$para[$index + 1]/@type eq 'whitespace' and $para[$index + 2]/@value eq 'in'">
<xsl:attribute name="id" select="concat('rng-',@value)"/>
</xsl:if>
</xsl:if>
<xsl:variable name="className">
<xsl:choose>
<xsl:when test="exists(@type)">
<xsl:value-of select="if (@type eq 'literal' and
matches(@value ,'select[\n\p{Zs}]*=[\n\p{Zs}]*[&quot;&apos;&apos;]'))
    then 'select'
else @type"/>
</xsl:when>
<xsl:otherwise>
<xsl:variable name="p" select="$para[$index - 1] "/>
<xsl:value-of select="if ($p/@type eq 'literal' and
matches($p/@value ,'name[\n\p{Zs}]*=[\n\p{Zs}]*[&quot;&apos;&apos;]'))
    then 'external'
else 'qname'"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:attribute name="class" select="$className"/>

<xsl:if test="$className eq 'external'">
<xsl:attribute name="id" select="concat('ext-',@value)"/>
</xsl:if>

<xsl:attribute name="start" select="@start"/>

<xsl:if test="(@value = ('(','[') or @type eq 'function') and not(@pair-end)">
<xsl:attribute name="style" select="'color: pink;'"/>
</xsl:if>

<xsl:if test="@pair-end">
<xsl:attribute name="pair-end" select="@pair-end"/>
</xsl:if>

<xsl:if test="not(@type) or 
(@type = ('function','filter','parenthesis','variable','node')) and (not(@value = (')',']'))) or
(@value eq '*' and $para[$index - 1]/@class eq 'axis')">
<xsl:attribute name="select" select="'quick'"/>
</xsl:if>

<xsl:choose>
<xsl:when test="@type = ('literal','comment')">
<xsl:analyze-string select="@value" regex="\n">
<xsl:matching-substring>
<br></br>
</xsl:matching-substring>
<xsl:non-matching-substring>
<xsl:value-of select="."/>
</xsl:non-matching-substring>
</xsl:analyze-string>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="@value"/>
</xsl:otherwise>
</xsl:choose>

</span>
</xsl:for-each>
</xsl:for-each>
</xsl:template>

<xsl:template match="token" mode="plainLine">
<span>
<xsl:attribute name="class" select="@type"/>
<xsl:attribute name="start" select="@start"/>
<xsl:variable name="revChars" select="reverse(string-to-codepoints(@value))" as="xs:integer*"/>
<xsl:variable name="lastLF" select="count($revChars) + 1 - index-of($revChars, 10)[1]"/>
<xsl:value-of select="substring(@value, $lastLF + 1)"/>
</span>
</xsl:template>

<xsl:template match="token" mode="dev">
<p><xsl:value-of select="@start"/></p>
</xsl:template>

<xsl:function name="loc:stringToCharSequence" as="xs:string*">
<xsl:param name="string"/>
<xsl:sequence select="for $i in 1 to string-length($string)
return substring($string, $i, 1)"/>
</xsl:function>

<xsl:function name="loc:createPairs" as="element()*">
<xsl:param name="brackets" as="element()*"/>
<xsl:variable name="nested" as="element()*">
<xsl:call-template name="getNesting">
<xsl:with-param name="positions" select="$brackets" tunnel="yes" as="element()*"/>
<xsl:with-param name="level" select="0" as="xs:integer"/>
<xsl:with-param name="index" select="1" as="xs:integer"/>
</xsl:call-template>
</xsl:variable>
<!--  pair up start and end elements -->
<xsl:variable name="ends" select="$nested[@end]"/>
<xsl:for-each select="$nested[@start]">
<xsl:variable name="start" select="@start" as="xs:integer"/>
<xsl:variable name="level" select="@level"/>
<xsl:variable name="pair" select="($ends[@level = $level])[number(@end) > $start][1]"
as="element()*"/>
<xsl:element name="{name(.)}">
<xsl:attribute name="start" select="$start"/>
<xsl:attribute name="level" select="$level"/>
<xsl:if test="$pair">
<xsl:attribute name="end" select="$pair/@end"/>
</xsl:if>
</xsl:element>
</xsl:for-each>
</xsl:function>

<xsl:template name="getNesting">
<xsl:param name="positions" tunnel="yes"/>
<xsl:param name="level" as="xs:integer"/>
<xsl:param name="index" as="xs:integer"/>

<xsl:variable name="pos" select="$positions[$index]"/>
<xsl:variable name="isOpen" select="$pos/@type = ('(','[', '(:')" as="xs:boolean"/>
<xsl:variable name="isBracket" select="$pos/@type = ('(',')')" as="xs:boolean"/>
<xsl:variable name="isComment" select="$pos/@type = ('(:',':)')" as="xs:boolean"/>
<xsl:variable name="blockType" select="if($isBracket) then 'bracket'
else if($isComment) then 'comment'
else 'predicate'"/>
<xsl:variable name="newLevel" select="if($isOpen) then
$level + 1 else $level - 1"/>

<xsl:choose>
<xsl:when test="empty($pos)"/>
<xsl:when test="$isOpen">
<xsl:element name="{$blockType}">
<xsl:attribute name="start" select="$pos/@position"/>
<xsl:attribute name="level" select="$newLevel"/>
</xsl:element>
</xsl:when>
<xsl:otherwise>
<xsl:element name="{$blockType}">
<xsl:attribute name="end" select="$pos/@position"/>
<xsl:attribute name="level" select="$level"/>
</xsl:element>
</xsl:otherwise>
</xsl:choose>

<xsl:choose>
<xsl:when test="$index + 1 > count($positions)"/>
<xsl:otherwise>
<xsl:call-template name="getNesting">
<xsl:with-param name="level" select="$newLevel" as="xs:integer"/>
<xsl:with-param name="index" select="$index + 1" as="xs:integer"/>
</xsl:call-template>
</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:function name="loc:createBlocks" as="element()*">
<xsl:param name="chars" as="xs:string*"/>
<xsl:param name="skip" as="xs:boolean"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:param name="awaiting" as="xs:string"/>
<xsl:param name="start" as="xs:integer"/>
<xsl:param name="level" as="xs:integer"/>

<xsl:variable name="charCount" select="count($chars)"/>

<xsl:variable name="char" select="$chars[$index]"/>
<xsl:variable name="nChar" select="$chars[$index + 1]"/>
<xsl:variable name="pChar" select="$chars[$index - 1]"/>

<xsl:variable name="newLevel" as="xs:integer">
<xsl:choose>
<xsl:when test="$awaiting = ':)'">
<xsl:value-of select="if($char = '(' and $nChar = ':') then $level + 1
else if ($char = ')' and $pChar = ':' and $level gt 0) then $level -1
else $level"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="$level"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:variable name="nowAwaiting">
<xsl:choose>
<xsl:when test="$awaiting=''">
<xsl:value-of select="if($char = ('&apos;&apos;','&quot;'))
then $char 
else if ($char = '(' and $nChar = ':') then ':)' 
else ''"/>
</xsl:when>
<xsl:when test="$char = $awaiting">
<xsl:value-of select="''"/>
</xsl:when>
<xsl:when test="$awaiting = ':)' and $char = ')' and $pChar = ':' and $level = 0">
<xsl:value-of select="''"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="$awaiting"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:variable name="nowSkip" as="xs:boolean">
<xsl:choose>
<xsl:when test="$skip">
<xsl:value-of select="false()"/>
</xsl:when>
<xsl:when test="$char = $awaiting and $nChar = $char">
<xsl:value-of select="true()"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="false()"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:if test="$awaiting = '' and $nowAwaiting = ''">
<xsl:if test="$char = ('[',']','(',')')">
<block position="{$index}" type="{$char}"/>
</xsl:if>
</xsl:if>

<xsl:variable name="isFound" as="xs:boolean"
select="not($awaiting = $nowAwaiting) and not($skip or $nowSkip)"/>

<xsl:variable name="newStart" as="xs:integer"
select="if ($isFound) then $index else $start"/>

<xsl:if test="$awaiting ne '' and $isFound">
<xsl:element name="{if ($awaiting = ':)') then 'comment' else 'literal'}">
<xsl:if test="$awaiting ne ':)'">
<xsl:attribute name="type" select="$char"/>
</xsl:if>
<xsl:attribute name="start" select="$start"/>
<xsl:attribute name="end" select="$index"/>
</xsl:element>
</xsl:if>

<xsl:choose>
<xsl:when test="$index eq $charCount">
<xsl:if test="$awaiting ne '' and not($isFound)">
<xsl:element name="{if ($awaiting = ':)') then 'comment' else 'literal'}">
<xsl:if test="$awaiting ne ':)'">
<xsl:attribute name="type" select="$awaiting"/>
</xsl:if>
<xsl:attribute name="start" select="$start"/>
</xsl:element>
</xsl:if>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="loc:createBlocks($chars, $nowSkip, $index + 1, $nowAwaiting, $newStart, $newLevel)"/>
</xsl:otherwise>
</xsl:choose>

</xsl:function>

<!-- top-level call - marks up tokens with their type -->
<xsl:function name="loc:getTokens">
<xsl:param name="chunk" as="xs:string"/>
<xsl:param name="omitPairs" as="element()*"/>
<xsl:param name="pbPairs" as="element()*"/>
<xsl:variable name="tokens" as="element()*"
select="loc:createTokens($chunk, $omitPairs, 1, 1)"/>

<xsl:sequence select="loc:rationalizeTokens($tokens, 1, false(), $pbPairs, false(), false())"/>

</xsl:function>


<xsl:function name="loc:rationalizeTokens">
<xsl:param name="tokens" as="element()*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:param name="prevIsClosed" as="xs:boolean"/>
<xsl:param name="pbPairs" as="element()*"/>
<xsl:param name="typeExpected" as="xs:boolean"/>
<xsl:param name="quantifierExpected" as="xs:boolean"/>

<!-- when closed, a probable operator is a QName instead -->

<xsl:variable name="token" select="$tokens[$index]" as="element()?"/>
<xsl:variable name="isQuantifier" select="$quantifierExpected and $token/@value = ('?','*','+')"/>
<xsl:variable name="currentIsClosed" as="xs:boolean"
select="$isQuantifier or not($token/@type) or ($token/@value = (')',']') or ($token/@type = ('literal','numeric','variable')))"/>
<xsl:element name="token">
<xsl:attribute name="start" select="$token/@start"/>
<xsl:attribute name="end" select="$token/@end"/>
<xsl:attribute name="value" select="$token/@value"/>

<xsl:choose>
<xsl:when test="$token/@type = 'probableOp'">
<xsl:if test="$prevIsClosed">
<xsl:attribute name="type" select="'op'"/>
</xsl:if>
</xsl:when>
<xsl:when test="not($isQuantifier) and not($prevIsClosed) and $token/@value eq '*'">
<!--
<xsl:attribute name="type" select="'any'"/>

--></xsl:when>
<xsl:when test="$token/@type = ('function','if', 'node') or $token/@value = ('(','[')">
<xsl:variable name="pair" select="$pbPairs[@start = $token/@end]"/>
<xsl:choose>
<xsl:when test="$typeExpected and $token/@type eq 'node'">
<xsl:attribute name="type" select="'node-type'"/>
</xsl:when>
<xsl:otherwise>
<xsl:attribute name="type" select="$token/@type"/>
</xsl:otherwise>
</xsl:choose>
<xsl:if test="not(empty($pair))">
<xsl:if test="$pair/@end">
<xsl:attribute name="pair-end" select="$pair/@end"/>
</xsl:if>
<xsl:attribute name="level" select="$pair/@level"/>
</xsl:if>
</xsl:when>
<xsl:when test="$typeExpected">
<xsl:attribute name="type" select="if ($token/@type) then $token/@type else 'type-name'"/>
</xsl:when>
<xsl:when test="$isQuantifier">
<xsl:attribute name="type" select="'quantifier'"/>
</xsl:when>
<xsl:when test="$token/@type">
<xsl:attribute name="type" select="$token/@type"/>
</xsl:when>
</xsl:choose>
</xsl:element>

<xsl:variable name="ignorable" as="xs:boolean"
select="$token/@type = ('whitespace', 'comment')"/>

<xsl:variable name="isNewClosed" as="xs:boolean">
<xsl:choose>
<xsl:when test="$ignorable">
<xsl:value-of select="$prevIsClosed"/>
</xsl:when>
<xsl:when test="$token/@type = 'probableOp'">
<xsl:value-of select="not($prevIsClosed)"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="$currentIsClosed"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:variable name="newTypeExpected" as="xs:boolean"
 select="if ($ignorable) then $typeExpected
 else $token/@type = 'type-op'"/>


<xsl:if test="$index + 1 le count($tokens)">
<xsl:variable name="qExpected" as="xs:boolean"
select="$typeExpected or $token/@value = ')'"/> 


<xsl:sequence select="loc:rationalizeTokens($tokens, $index + 1, $isNewClosed,
$pbPairs, $newTypeExpected, $qExpected)"/>
</xsl:if>
<!-- check tokens like -->
</xsl:function>


<xsl:function name="loc:createTokens">
<xsl:param name="string" as="xs:string"/>
<xsl:param name="excludes" as="element()*"/>
<xsl:param name="start" as="xs:integer"/>
<xsl:param name="index" as="xs:integer"/>

<xsl:variable name="exclude" as="element()?"
select="$excludes[$index]"/>

<xsl:variable name="end" as="xs:integer?"
select="if (empty($exclude)) then ()
else if ($exclude/@end) then 
$exclude/@end cast as xs:integer + 1
else ()"/>

<xsl:variable name="exStart" as="xs:integer?"
select="if (empty($exclude)) then ()
else $exclude/@start"/>

<xsl:variable name="part">
<xsl:choose>
<xsl:when test="empty($exclude) and $index = 1">
<xsl:value-of select="$string"/>
</xsl:when>
<xsl:when test="exists($exStart) and $exStart ge $start">
<xsl:value-of select="substring($string, $start, $exStart - $start)"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="substring($string, $start, string-length($string) + 1 - $start)"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:if test="string-length($part) gt 0">
<xsl:variable name="tokens" as="xs:string*"
select="loc:rawTokens($part)"/>

<!-- The XSLT that generates the tokens -->
<xsl:sequence select="loc:processTokens($tokens, $start, 1)"/>
</xsl:if>

<xsl:if test="not(empty($exclude))">
<xsl:element name="token">
<xsl:attribute name="start" select="$exclude/@start"/>
<xsl:if test="$exclude/@end">
<xsl:attribute name="end" select="$exclude/@end"/>
</xsl:if>
<xsl:variable name="stringEnd">
<xsl:value-of select="if ($exclude/@end) then $exclude/@end else string-length($string)"/>
</xsl:variable>
<xsl:attribute name="value">
<xsl:value-of select="substring($string, $exclude/@start, $stringEnd + 1 - $exclude/@start)"/>
</xsl:attribute>
<xsl:attribute name="type" select="name($exclude)"/>
</xsl:element>
</xsl:if>
<!-- iterate 1 pos beyond end of excludes length -->
<xsl:if test="not(empty($excludes)) and not(empty($end)) and $index le count($excludes)">
<xsl:sequence select="loc:createTokens($string, $excludes, $end, $index + 1)"/>
</xsl:if>
</xsl:function>

<xsl:function name="loc:processTokens" as="element()*">
<xsl:param name="tokens" as="xs:string*"/>
<xsl:param name="start" as="xs:integer"/>
<xsl:param name="index" as="xs:integer"/>

<xsl:variable name="token" as="xs:string?"
select="$tokens[$index]"/>
<xsl:variable name="end" as="xs:integer"
select="$start + string-length($token)"/>
<xsl:element name="token">
<xsl:attribute name="start" select="$start"/>
<xsl:attribute name="end" select="$end - 1"/>
<xsl:attribute name="value" select="$token"/>
<xsl:variable name="isSimpleOps" select="$token = $simpleOps" as="xs:boolean"/>
<xsl:if test="$isSimpleOps">
<xsl:attribute name="type" select="if($token = ('/','//')) then 'step' else 'op'"/>
</xsl:if>
<xsl:variable name="isDoubleToken" as="xs:boolean">
<xsl:choose>
<xsl:when test="$isSimpleOps">
<xsl:value-of select="false()"/>
</xsl:when>
<xsl:otherwise>
<xsl:variable name="splitToken" as="xs:string*"
select="tokenize($token, '[\n\p{Zs}]+')"/>
<xsl:value-of
select="if (count($splitToken) ne 2) then false()
else if ($splitToken[1] eq 'instance' and $splitToken[2] eq 'of') 
then true()
else if ($splitToken[1] = ('cast','castable','treat') and $splitToken[2] eq 'as')
then true() else false()"/>

</xsl:otherwise>
</xsl:choose>
</xsl:variable>
<xsl:if test="$isDoubleToken">
<xsl:attribute name="type" select="'type-op'"/>
</xsl:if>

<xsl:variable name="functionType" as="xs:string">
<xsl:choose>
<xsl:when test="$isSimpleOps or $isDoubleToken or string-length($token) = 1 or not(ends-with($token,'('))">
<xsl:text></xsl:text>
</xsl:when>
<xsl:otherwise>
<xsl:variable name="fnName" as="xs:string" select="tokenize($token, '[\n\p{Zs}]+|\(')[1]"/>
<xsl:choose>
<xsl:when test="$fnName = 'if'">
<xsl:text>if</xsl:text>
</xsl:when>
<xsl:when test="some $n in $nodeTests satisfies $n = $fnName">
<xsl:text>node</xsl:text>
</xsl:when>
<xsl:when test="some $x in $typeTests satisfies $x = $fnName">
<xsl:text>type</xsl:text>
</xsl:when>
<xsl:otherwise>
<xsl:text>function</xsl:text>
</xsl:otherwise>
</xsl:choose>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>
<xsl:choose>
<xsl:when test="$isSimpleOps or $isDoubleToken"></xsl:when>
<xsl:when test="$functionType ne ''">
<xsl:attribute name="type" select="$functionType"/>
</xsl:when>
<xsl:when test="ends-with($token, '::') or $token eq '@'">
<xsl:attribute name="type" select="'axis'"/>
</xsl:when>
<xsl:when test="matches($token,'[\n\p{Zs}]+')">
<xsl:attribute name="type" select="'whitespace'"/>
</xsl:when>
<xsl:when test="$token = ('.','..')">
<xsl:attribute name="type" select="'context'"/>
</xsl:when>
<xsl:when test="$token = ('(',')')">
<xsl:attribute name="type" select="'parenthesis'"/>
</xsl:when>
<xsl:when test="$token = ('[',']')">
<xsl:attribute name="type" select="'filter'"/>
</xsl:when>
<xsl:when test="number($token) = number($token)">
<xsl:attribute name="type" select="'numeric'"/>
</xsl:when>
<xsl:when test="$token = $ambiguousOps">
<xsl:attribute name="type" select="'probableOp'"/>
</xsl:when>
<xsl:when test="$token = $higherOps">
<xsl:if test="starts-with(loc:nextNonWhite($tokens, $index), '$')">
<xsl:attribute name="type" select="'higher'"/>
</xsl:if>
</xsl:when>
<xsl:when test="$token eq 'if'">
<xsl:if test="loc:nextNonWhite($tokens, $index) eq '('">
<xsl:attribute name="type" select="'if'"/>
</xsl:if>
</xsl:when>
<xsl:when test="starts-with($token, '$')">
<xsl:attribute name="type" select="'variable'"/>
</xsl:when>
</xsl:choose>
</xsl:element>

<xsl:if test="$index + 1 le count($tokens)">
<xsl:sequence select="loc:processTokens($tokens, $end, $index + 1)"/>
</xsl:if>
</xsl:function>

<xsl:function name="loc:nextNonWhite" as="xs:string?">
<xsl:param name="tokens" as="xs:string*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:choose>
<xsl:when test="true()"><!-- test="$index + 2 lt count($tokens)">  --> 
<xsl:value-of select="if(replace($tokens[$index + 1],'[\n\p{Zs}]+','') eq '')
then $tokens[$index + 2] else $tokens[$index + 1]"/>
</xsl:when>
<xsl:otherwise></xsl:otherwise>
</xsl:choose>
</xsl:function>

<xsl:function name="loc:rawTokens" as="xs:string*">
<xsl:param name="chunk" as="xs:string"/>
<xsl:analyze-string
regex="(((-)?\d+)(\.)?(\d+([eE][\+\-]?)?\d*)?)|(\?)|(instance[\n\p{{Zs}}]+of)|(cast[\n\p{{Zs}}]+as)|(castable[\n\p{{Zs}}]+as)|(treat[\n\p{{Zs}}]+as)|((\$[\n\p{{Zs}}]*)?[\i\*][\p{{L}}\p{{Nd}}\.\-]*(:[\p{{L}}\p{{Nd}}\.\-\*]*)?(::)?:?)(\()?|(\.\.)|((-)?\d?\.\d*)|-|([&lt;&gt;!]=)|(&gt;&gt;|&lt;&lt;)|(//)|([\n\p{{Zs}}]+)|(\C)"
select="$chunk">
<xsl:matching-substring>
<xsl:value-of select="string(.)"/>
</xsl:matching-substring>
</xsl:analyze-string>
</xsl:function>

</xsl:transform>
