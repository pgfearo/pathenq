<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:js="http://saxonica.com/ns/globalJS"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:style="http://saxonica.com/ns/html-style-property"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:loc="com.qutoric.sketchpath.functions"
extension-element-prefixes="ixsl"
xmlns:f="internal">

<xsl:template name="main">
<xsl:result-document href="#source" method="replace-content">
<xsl:sequence select="f:render()"/>
</xsl:result-document>
</xsl:template>

<xsl:function name="f:render">
<xsl:variable name="xmlText" select="js:getSourceText()"/>
<xsl:variable name="tokens" as="xs:string*" select="js:splitString($xmlText)"/>

<xsl:message><xsl:value-of select="count($tokens)"/></xsl:message>
<xsl:variable name="spans" select="f:iterateTokens(0, $tokens,1,'n',0, 0)" as="element()*"/>

<xsl:sequence select="$spans"/>
</xsl:function>

<xsl:function name="f:getTagType">
<xsl:param name="token" as="xs:string?"/>
<xsl:variable name="t" select="$token"/>
<xsl:variable name="t1" select="substring($t,1,1)"/>
<xsl:variable name="t2" select="substring($t,2,1)"/>

<xsl:choose>
<xsl:when test="$t1 eq '?'"><xsl:sequence select="'pi','?'"/></xsl:when>
<xsl:when test="$t1 eq '!' and $t2 eq '-'"><xsl:sequence select="'cm','!--'"/></xsl:when>
<xsl:when test="$t1 eq '!' and $t2 eq '['"><xsl:sequence select="'cd','![CDATA['"/></xsl:when>
<xsl:when test="$t1 eq '!'"><xsl:sequence select="'dt','!'"/></xsl:when>
<xsl:when test="$t1 eq '/'"><xsl:sequence select="'cl','/'"/></xsl:when>
<!-- open tag (may be  self-closing) -->
<xsl:otherwise><xsl:sequence select="'tg',''"/></xsl:otherwise>
</xsl:choose>
</xsl:function>

<xsl:template name="delayed-iterate">
<xsl:param name="counter" as="xs:integer"/>
<xsl:param name="tokens" as="xs:string*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:param name="expected" as="xs:string"/>
<xsl:param name="beganAt" as="xs:integer"/>
<xsl:param name="level" as="xs:integer"/>
<xsl:result-document href="#source" method="append-content">
<xsl:sequence select="f:iterateTokens($counter, $tokens, $index, $expected, $beganAt, $level)"/>
</xsl:result-document>
</xsl:template>

<xsl:function name="f:expected-offset" as="xs:integer">
<xsl:param name="in"/>
<xsl:value-of select="if ($in eq '?&gt;') then 2
else if ($in eq '--&gt;') then 3
else if ($in eq ']]>') then 9
else 1"/>
</xsl:function>

<xsl:function name="f:iterateTokens" as="element()*">
<xsl:param name="counter" as="xs:integer"/>
<xsl:param name="tokens" as="xs:string*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:param name="expected" as="xs:string"/>
<xsl:param name="beganAt" as="xs:integer"/>
<xsl:param name="level" as="xs:integer"/>
<xsl:variable name="token" select="$tokens[$index]" as="xs:string?"/>
<xsl:variable name="prevToken" select="$tokens[$index + 1]" as="xs:string?"/>
<xsl:variable name="nextToken" select="$tokens[$index - 1]" as="xs:string?"/>
<xsl:variable name="awaiting" select="$expected ne 'n'" as="xs:boolean"/>


<!--
<trace>
token: <xsl:value-of select="$token"/>
expected: <xsl:value-of select="$expected"/>
index: <xsl:value-of select="$index"/>
</trace>

-->

<xsl:variable name="expectedOutput" as="element()*">
<xsl:if test="$awaiting">
<!--  looking to close an open tag -->
<!-- consider: <!DOCTYPE person [<!ELEMENT ... ]> as well as reference only -->
<xsl:variable name="beforeFind" select="substring-before($token, $expected)"/>
<xsl:variable name="found"
select="if (string-length($beforeFind) gt 0)
then true() 
else starts-with($beforeFind, $expected)" as="xs:boolean"/>
<xsl:if test="$found">
<xsl:variable name="offset" select="f:expected-offset($expected)" as="xs:integer"/>
<xsl:variable name="begin-token" select="$tokens[$beganAt]"/>
<span class="z">
<xsl:value-of
select="concat('&lt;',substring($begin-token, 1, $offset))"/>
</span>
<xsl:variable name="part-token" select="substring($begin-token, $offset + 1)"/>
<xsl:element name="span">
<xsl:attribute name="class" select="f:getTagType($tokens[$beganAt])[1]"/>
<xsl:attribute name="closex" select="$expected"/>
<xsl:value-of 
select="string-join(
($part-token,
for $x in $beganAt + 1 to ($index -1) return
concat('&lt;', $tokens[$x]),
'&lt;',$beforeFind)
, '')
"/>
</xsl:element>
<span class="z"><xsl:value-of select="$expected"/></span>
<span class="txt">
<xsl:value-of select="substring($token, string-length($beforeFind) + string-length($expected) + 1)"/>
</span>
</xsl:if>
</xsl:if>
</xsl:variable>

<!-- return 2 strings if required close found - that befoe and that after (even if empty string)
     if no required close found - just return the required close -->
<xsl:variable name="parseStrings" as="element()*">
<xsl:if test="not($awaiting)">
<xsl:variable name="char1" as="xs:string?" select="substring($token,1,1)"/>
<xsl:variable name="requiredClose" as="xs:string">
<xsl:variable name="char2" as="xs:string?" select="substring($token,2,1)"/>
<xsl:choose>
<xsl:when test="$char1 eq '?'">?&gt;</xsl:when>
<xsl:when test="$char1 eq '!' and $char2 eq '-'">--&gt;</xsl:when>
<xsl:when test="$char1 eq '!' and $char2 eq '['">]]&gt;</xsl:when> <!-- assume cdata: <![CDATA[]]> -->
<xsl:when test="$char1 eq '!'">
<xsl:value-of select="if (contains($token,'[')) then ']>' else '>'"/>
</xsl:when>
<xsl:otherwise>&gt;</xsl:otherwise>
</xsl:choose>
</xsl:variable>

<xsl:variable name="beforeClose" select="substring-before($token, $requiredClose)" as="xs:string"/>

<xsl:choose>
<xsl:when test="string-length($token) eq 0">
<!--
<x/>
-->
</xsl:when>
<xsl:when test="$char1 = ('?','!','/')">
<!-- cdata, dtd, pi, comment, or close-tag -->
<xsl:variable name="foundClose"
select="if (string-length($beforeClose) gt 0)
then true() 
else starts-with($beforeClose, $requiredClose)"
as="xs:boolean"/>
<xsl:choose>
<xsl:when test="$foundClose">
<xsl:variable name="tagType" select="f:getTagType($token)" as="xs:string+"/>
<xsl:variable name="tagStart" select="$tagType[2]"/>

<span class="z"><xsl:value-of select="concat('&lt;',$tagStart)"/></span>


<span class="{$tagType[1]}" closey="{$requiredClose}">
<xsl:value-of select="substring($beforeClose, string-length($tagStart) + 1)"/>
</span>
<span class="z"><xsl:value-of select="$requiredClose"/></span>
<span class="txt">
<xsl:value-of select="substring($token, string-length($beforeClose) + string-length($requiredClose) + 1)"/>
</span>
</xsl:when>
<xsl:otherwise>
<required>
<xsl:value-of select="$requiredClose"/>
</required>
</xsl:otherwise>
</xsl:choose>
</xsl:when>
<xsl:otherwise>
<!--
<xsl:variable name="pre-text" select="substring-before($token, '>')"/>

-->
<xsl:variable name="parts" as="xs:string*">
<xsl:analyze-string regex="&quot;.*?&quot;|'.*?'|[^'&quot;]+|['&quot;]" select="$token" flags="s">
<xsl:matching-substring>
<xsl:value-of select="."/>
</xsl:matching-substring>
<xsl:non-matching-substring>
<xsl:value-of select="."/>
</xsl:non-matching-substring>
</xsl:analyze-string>
</xsl:variable>

<xsl:variable name="pre-text" select="substring-before($parts[1], '>')"/>

<!--
<span>[parts]<xsl:value-of select="string-join($parts,'/')"/></span>
-->

<xsl:sequence select="f:getAttributes($token, 0, $parts, 1)"/>

<!-- must be an open tag, so check for attributes -->

</xsl:otherwise>
</xsl:choose>
</xsl:if>
</xsl:variable>

<xsl:variable name="newLevel" as="xs:integer">
<xsl:choose>
<xsl:when test="exists($parseStrings)">
<xsl:variable name="f" select="$parseStrings[1]" 
as="element()"/>
<xsl:value-of select="if ($f/@class eq 'cl') then $level - 1
else if ($f/@class eq 'en') 
then
(if ((exists($parseStrings[@class = 'enx']))) then $level
else $level + 1)
else if ($f/@class eq 'enc')
then $level - 1
else $level"/>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="$level"/>
</xsl:otherwise>
</xsl:choose>
</xsl:variable>


<!--  for diagnostics - to check asynchronous calling is not interleaved -->
<!--
<span>[index: <xsl:value-of select="$index"/>]</span>
-->

<xsl:variable name="stillAwaiting" as="xs:boolean"
select="$awaiting and empty($expectedOutput)"/>

<xsl:if test="not(name($parseStrings[1]) eq 'required')">
<xsl:sequence select="$parseStrings"/>
</xsl:if>
<!--
<xsl:message><xsl:sequence select="$parseStrings"/></xsl:message>
-->

<!--
<xsl:if test="exists($expectedOutput)">
<span style="color:red">beginExpected</span>

-->
<xsl:sequence select="$expectedOutput"/>

<!--
<span style="color:red">endExpected</span>
</xsl:if>

-->
<!-- following for diagnostics only -->

<!--
<firstName><xsl:value-of select="name($parseStrings[1])"/></firstName>
<firstClass><xsl:value-of select="$parseStrings[1]/@class"/></firstClass>
<level><xsl:value-of select="$level"/></level>
<newLevel><xsl:value-of select="$newLevel"/></newLevel>

-->

<xsl:variable name="newExpected" as="xs:string"
select="if ($index eq 1) then
'n'
else if ($stillAwaiting)
then $expected
else if (count($parseStrings) eq 1)
then $parseStrings
else 'n'"/>

<xsl:variable name="newBeganAt" as="xs:integer"
select="if ($stillAwaiting) then $beganAt else $index"/>


<xsl:if test="$index le count($tokens)">
<xsl:choose>
<xsl:when test="$counter eq 40">

<!--
<h2>[Index] <xsl:value-of select="$index"/></h2>
-->

<!--
Scheduled action used to improve perception of XML page loading
setting wait to 1ms caused interleaving of asynchrous DOM writes
-->
<ixsl:schedule-action wait="5">
<xsl:call-template name="delayed-iterate">
<xsl:with-param name="counter" select="$counter + 1"/>
<xsl:with-param name="tokens" select="$tokens" as="xs:string*"/>
<xsl:with-param name="index" select="$index + 1" as="xs:integer"/>
<xsl:with-param name="expected" select="$newExpected" as="xs:string"/>
<xsl:with-param name="beganAt" select="$newBeganAt" as="xs:integer"/>
<xsl:with-param name="level" select="$newLevel" as="xs:integer"/>
</xsl:call-template>
</ixsl:schedule-action>
</xsl:when>
<xsl:otherwise>
<xsl:sequence select="f:iterateTokens($counter + 1, $tokens, $index + 1, $newExpected, $newBeganAt, $newLevel)"/>
</xsl:otherwise>
</xsl:choose>
</xsl:if>
</xsl:function>

<xsl:function name="f:getAttributes" as="element()*">
<xsl:param name="attToken" as="xs:string"/>
<xsl:param name="offset" as="xs:integer"/>
<xsl:param name="parts" as="xs:string*"/>
<xsl:param name="index" as="xs:integer"/>
<xsl:variable name="part1" as="xs:string?"
select="$parts[$index]"/>
<xsl:variable name="part2" as="xs:string?"
select="$parts[$index + 1]"/>

<xsl:variable name="elementName" as="xs:string?">
<xsl:if test="$index eq 1">
<xsl:value-of select="js:splitElementName($part1)[1]"/>
</xsl:if>
</xsl:variable>

<xsl:if test="$index eq 1">
<span class="z">&lt;</span>
<span class="en">
<xsl:value-of select="$elementName"/>
</span>
</xsl:if>

<xsl:variable name="pre-close" select="substring-before($part1, '>')"/>

<xsl:variable name="isFinalPart" select="$index + 2 gt count($parts)
or string-length($pre-close) gt 0
or starts-with($part1,'>')"
as="xs:boolean"/>

<xsl:if test="$isFinalPart">
<span class="z"><xsl:value-of select="if (ends-with($pre-close,'/')) then '/' else ''"/>&gt;</span>
<span class="txt">
<xsl:value-of select="substring($attToken, string-length($pre-close) + $offset + 2)"/>
</span>

</xsl:if>

<xsl:choose>
<xsl:when test="$isFinalPart"/>
<xsl:when test="exists($part2)">
<!-- attribute must exist and name occurs before value, so get this first -->
<xsl:variable name="left" as="xs:string"
select="if ($index eq 1)
then substring($part1, string-length($elementName) + 1)
else $part1"/>
<xsl:variable name="pre" select="substring-before($left,'=')"/>
<xsl:variable name="tokens" select="js:splitAttributeName($pre)"/>
<xsl:for-each select="$tokens">
<xsl:variable name="class" select="if (js:isWord(.)) then 'atn' else 'z'"/>
<span class="{$class}"><xsl:value-of select="."/></span>
</xsl:for-each>
<span class="z"><xsl:value-of select="substring($left,string-length($pre) + 1)"/></span>

<xsl:variable name="sl" select="string-length($part2)" as="xs:double"/>
<span class="z"><xsl:value-of select="substring($part2,1,1)"/></span>
<span class="av">
<xsl:value-of select="substring($part2, 2, $sl - 2)"/>
</span>
<span class="z"><xsl:value-of select="substring($part2, $sl)"/></span>
</xsl:when>

</xsl:choose>

<xsl:variable name="newOffset" select="string-length($part1) + string-length($part2) + $offset"/>

<xsl:if test="not($isFinalPart)">
<xsl:sequence select="f:getAttributes($attToken, $newOffset, $parts, $index + 2)"/>
</xsl:if>

</xsl:function>

</xsl:stylesheet>
