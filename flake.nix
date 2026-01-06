{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { } :
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
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                let
                                                                    init = implementation.init { mount = mount ; pkgs = pkgs ; resources = resources ; root = root ; wrap = wrap ; } ;
                                                                    instance = implementation { expression = expression ; targets = targets ; } ;
                                                                    in
                                                                        writeShellApplication
                                                                            {
                                                                                name = "install-check" ;
                                                                                runtimeInputs = [ coreutils failure ] ;
                                                                                text =
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        touch "$OUT"
                                                                                        ${ if [ "init" "targets" ] != builtins.attrNames instance then ''failure b94ff7e6 "We expected the names to be init and targets" "${ builtins.concatStringsSep "," ( builtins.attrNames instance ) }"'' else "#" }
                                                                                        ${ if targets != instance.targets then ''failure c5dae5cf "We expected the targets to be as specified" "${ builtins.concatStringsSep "," ( builtins.attrNames instance.targets ) }" }"'' else "#" }
                                                                                        ${ if init != expected then ''failure 3ae22bf6 "We expected the init to match" ${ init }'' else "#" }
                                                                                    '' ;
                                                                            }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    # implementation = implementation ;
                                } ;
            } ;
}