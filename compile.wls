#!/usr/bin/env wolframscript

$sourceDirectory = "functions"
$sourceFileExtensionPattern = "wl" | "m" | "wxf" | "mx"

$buildDirectory = "compiled"
Quiet@CreateDirectory[$buildDirectory]

$platformLibraryExtension = $OperatingSystem // Replace[{
    "Windows" -> "dll",
    "MacOSX" -> "dylib",
    "Unix" -> "so",
    _ -> None
}]
If[
    (* if the $OperatingSystem is not a known value *)
    !StringQ[$platformLibraryExtension],
    (* then print a failure message and exit *)
    Print@TemplateApply[
        "ERROR: Unsupported $OperatingSystem \"`1`\"",
        $OperatingSystem
    ];
    Exit[1]
]

functionPathsToCompile = FileNames[
    __ ~~ "." ~~ $sourceFileExtensionPattern,
    $sourceDirectory
]

If[
    (* if no function files were found *)
    Length[functionPathsToCompile] === 0,
    (* then print a failure message and exit *)
    Print@TemplateApply[
        "ERROR: No function source files found in directory \"`1`\"",
        $sourceDirectory
    ];
    Exit[1]
]

Print["Function(s) to compile: ", functionPathsToCompile]

compilationResults = functionPathsToCompile // Map[
    Function[functionPath, Module[{
        compiledFunctionPath = FileNameJoin[{
            $buildDirectory,
            FileBaseName[functionPath] <> "." <> $platformLibraryExtension
        }],
        functionExpression,
        compilationResult
    },

        (* import function *)
        Print@TemplateApply["Importing function from '`1`'...", {functionPath}];

        functionExpression = Import[functionPath];
        If[
            (* if the import failed *)
            FailureQ[functionExpression],
            (* then print a failure message and exit *)
            Print@TemplateApply["ERROR: failed to import function from '`1`'.", {functionPath}];
            Exit[1]
        ];

        (* compile function *)
        Print@TemplateApply[
            "Compiling function from '`1`' to '`2`'...",
            {functionPath, compiledFunctionPath}
        ];

        compilationResult = FunctionCompileExportLibrary[compiledFunctionPath, functionExpression];
        If[
            (* if FunctionCompileExportLibrary didn't return a file path *)
            !StringQ[compilationResult],
            (* then print a failure message and exit *)
            Print@TemplateApply[
                "ERROR: failed to compile function from '`1`' to '`2`'.",
                {functionPath, compiledFunctionPath}
            ];
            Print["FunctionCompileExportLibrary returned:"];
            Echo[compilationResult];
            Exit[1]
        ];

        Print@TemplateApply[
            "Successfully compiled function from '`1`' to '`2`'.",
            {functionPath, compiledFunctionPath}
        ];

        compilationResult
    ]]
]

Print@TemplateApply["Successfully compiled `1` function(s)!", Length[compilationResults]]

Exit[0]
