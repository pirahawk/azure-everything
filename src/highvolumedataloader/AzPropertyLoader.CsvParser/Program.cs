
using System.Reflection;

const string FilePath=@"";
// See https://aka.ms/new-console-template for more information


// var currentAssembly = Assembly.GetCallingAssembly();

// var dir = Path.GetDirectoryName(currentAssembly.Location);


// var t = currentAssembly.GetTypes().Where(t => t.Namespace != null && t.Namespace.Contains("AzPropertyLoader")).FirstOrDefault()?.Namespace;

// var codebase = currentAssembly.CodeBase;

// var test = Directory.GetParent(dir);

using FileStream reader = File.OpenRead(FilePath);
using StreamReader streamReader = new StreamReader(reader);

var numLoops = 100;
var counter = 0;

//while (counter++<numLoops){
try{
while (streamReader.Peek() > -1){
    var line = streamReader.ReadLine();
    //System.Console.WriteLine($"{counter}:{line}");
}

System.Console.WriteLine($"{reader.Length} : {reader.Position}");


}catch(Exception e){

}



Console.WriteLine("Hello, World!");
