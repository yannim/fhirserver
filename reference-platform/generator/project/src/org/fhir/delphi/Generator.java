package org.fhir.delphi;

import org.hl7.fhir.utilities.TextFile;

public class Generator {

  public static void main(String[] args) throws Exception {
    System.out.println("Generate pascal code for dstu"+args[2]+" in "+args[1]+" from "+args[0]);
    Definitions definitions;
    if (args[2].equals("3"))
      definitions = new DefinitionsLoader3().loadDefinitions(args[0]);
    else
      definitions = new DefinitionsLoader2().loadDefinitions(args[0]);
    TextFile.stringToFile(new DefinitionDumper().dumpDefinitions(definitions), "c:\\temp\\pascal.txt");
    new DelphiGenerator(args[1]).generate(definitions, definitions.getVersion(), definitions.getGenDate(), Integer.parseInt(args[2]));
    System.out.println("Done");
  }

}
