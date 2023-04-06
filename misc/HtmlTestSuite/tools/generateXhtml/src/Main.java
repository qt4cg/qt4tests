import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.XdmNode;
import org.jsoup.nodes.Document;
import org.jsoup.parser.Parser;

import java.io.*;

public class Main {
    public static void main(String[] args) throws Exception {

        Parser parser = Parser.htmlParser();

        File dir = new File("/Users/mike/GitHub/qt4cg/qt4tests/misc/HtmlTestSuite/files/");
        File outDir = new File("/Users/mike/GitHub/qt4cg/qt4tests/misc/HtmlTestSuite/results/");
        File[] files = dir.listFiles();
        
        for (File f : files) {
            try {
                System.err.println("Processing " + f.getName());
                Document doc = parser.parseInput(new BufferedReader(new FileReader(f)), dir.toURI().toString());
                String xml = serialize(doc);
                File outFile = new File(outDir, f.getName().replace(".html", ".xhtml"));
                outFile.createNewFile();
                PrintStream ps = new PrintStream(outFile);
                ps.print(xml);
            } catch (Exception e) {
                System.err.println("**** Failed to convert " + f.getName() + " - " + e.getMessage());
            }
        }
    }

    public static String serialize(Document doc) throws SaxonApiException {
        org.w3c.dom.Document dom = ConvertToDom.convert(doc);
        Processor proc = new Processor(true);
        StringWriter sw = new StringWriter();
        Serializer serializer = proc.newSerializer(sw);
        serializer.setOutputProperty(Serializer.Property.METHOD, "xml");
        serializer.setOutputProperty(Serializer.Property.INDENT, "no");
        serializer.setOutputWriter(sw);
        XdmNode wrappedDom = proc.newDocumentBuilder().wrap(dom);
        serializer.serialize(wrappedDom.asSource());
        return sw.toString();
    }

}