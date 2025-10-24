{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        coreutils ,
                        nix ,
                        package ,
                        target ,
                        writeShellApplication
                    } :
                        let
                            implementation =
                                {
                                    init =
                                        { resources , self } :
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "init" ;
                                                            runtimeInputs = [ coreutils nix ] ;
                                                            text =
                                                                ''
                                                                    mkdir --parents /mount/bin
                                                                    TARGET_1="$( nix shell ${ package } nixpkgs#which --command which ${ target } )" || failure 1
                                                                    export TARGET_1
                                                                    TARGET_2="$( nix shell ${ package } nixpkgs#which --command which ${ target } )" || failure 2
                                                                    ln --symbolic "$TARGET_2" /mount/bin
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/init" ;
                                    targets = [ "bin" ] ;
                                    transient = false ;
                                } ;
                            in
                                {
                                    check =
                                        {
                                            expected-init ,
                                            failure ,
                                            mkDerivation
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase =
                                                        ''
                                                            execute-test "$out"
                                                        '' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test" ;
                                                                        runtimeInputs = [ ( failure "42ad3053" ) ] ;
                                                                        text =
                                                                            let
                                                                                observed-init = implementation.init { resources = null ; self = null ; } ;
                                                                                in
                                                                                    ''
                                                                                        if [[ "${ expected-init }" != "${ observed-init }" ]]
                                                                                        then
                                                                                            failure "We expected the init to be ${ expected-init } but we observed ${ observed-init }" ;-
                                                                                        fi
                                                                                        if [[ '"[\"bin\"]"' != ${ builtins.toJSON implementation.targets } ]]
                                                                                        then
                                                                                            failure "We expected the targets to be bin"
                                                                                        fi
                                                                                        if [[ '"false"' != ${ builtins.toJSON implementation.transient } ]]
                                                                                        then
                                                                                            failure "We expected transient to be false"
                                                                                        fi
                                                                                    '' ;
                                                                    }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}