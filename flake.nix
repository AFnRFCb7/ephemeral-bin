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
                                                                    nix-shell --package ${ package } --run "ln --symbolic ${ target } /mount/bin
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/init" ;
                                    targets = [ "bin" ] ;
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