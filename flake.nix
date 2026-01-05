{
    inputs = { } ;
    outputs =
        { self } :
            let
                implementation =
                    { expression , targets } :
                        {
                            init =
                                { mount , pkgs , resources , root , wrap } :
                                    let
                                        application =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "init" ;
                                                    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.nix ] ;
                                                    text =
                                                        ''
                                                            cd /scratch
                                                            nix build --expr ${ expression }
                                                            find /scratch/result -mindepth 1 -maxdepth 1 -exec ln --symbolic {} /mount \;
                                                        '' ;
                                                } ;
                                        in "${ application }/bin/init" ;
                            targets = targets ;
                        } ;
                in
                    {
                        check =
                            {
                                coreutils ,
                                expected ,
                                expression ? "ea8f68e5" ,
                                failure ,
                                mkDerivation ,
                                targets ? "8decf091" ,
                                writeShellApplication
                            } :
                                mkDerivation
                                    {
                                        installPhase = ''install-check "$out"'' ;
                                        name = "check" ;
                                        nativeInputs =
                                            [
                                                (
                                                    let
                                                        observed = implementation { expression = expression ; targets = targets ; } ;
                                                        in
                                                            if expected == observed then
                                                                writeShellApplication
                                                                    {
                                                                        name = "install-check" ;
                                                                        runtimeInputs = [ coreutils ] ;
                                                                        text =
                                                                            ''
                                                                                OUT="$1"
                                                                                touch "$OUT"
                                                                            '' ;
                                                                    }
                                                            else
                                                                writeShellApplicationn
                                                                    {
                                                                        name = "install-check" ;
                                                                        runtimeInputs = [ coreutils ] ;
                                                                        text =
                                                                            ''
                                                                                OUT="$1"
                                                                                touch "$OUT"
                                                                                failure 9c568b42 "We expected expected to be observed" "EXPECTED=${ expected }" "OBSERVED=${ observed }"
                                                                            '' ;
                                                                    }
                                                )
                                            ] ;
                                        src = ./. ;
                                    }
                        implementation = implementation ;

                    } ;
}