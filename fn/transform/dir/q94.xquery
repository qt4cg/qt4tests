let $result := fn:transform(map {"stylesheet-location" : "../identity.xsl", 
                                 "source-location" : "../sections.xml"
                                })
return $result?output