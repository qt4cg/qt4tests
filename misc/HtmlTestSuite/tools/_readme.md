# Generating the HtmlTestSuite

The tests in this test-set have been generated as follows.

1. Clone the Github repository https://github.com/web-platform-tests/wpt

2. Run the stylesheet selectFiles.xsl (initial template main) with the $repo parameter set to the directory in which the wpt tests were cloned. 
This stylesheet makes a non-random selection of HTML files from the repository. Specifically, it calculates a signature for each file (containing the concatenation of the HTML start tags), then groups the files by signature (because it's not interesting to process multiple files with the same structure), then selects the first file in every tenth group, to give a hopefully varied selection of raw material. The resulting files are placed in the "files" directory

3. Run the Java application in generateXhtml. This uses JSoup and Saxon to create XHTML equivalents of the HTML5 files in "files", placing the output in "results". This program uses custom code to convert the tree produced by the JSoup parser into a DOM, and then uses Saxon to serialize the DOM as XHTML. The custom code is based on  https://github.com/jhy/jsoup/blob/master/src/main/java/org/jsoup/helper/W3CDom.java but heavily adapted to handle edge cases such as invalid attribute names, "--" in comments, etc. The idea is that this should generate XHTML whose XDM model compares deep-equal to the result of fn:parse-html() applied to the raw HTML5 file.
4. (Note: the generateXml.xsl stylesheet was a unsuccessful attempt to do step 2 in XSLT).

5. Run Generator.xq to generate the test set.
