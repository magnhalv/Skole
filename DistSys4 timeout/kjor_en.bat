for %%s in (1 2 3 4) do java VentLitt && start kjor_to.bat %1 %2 %3 %%s
@echo Kjør test case %3, lukk alle servere og trykk en tast når du vil gå videre til neste case.
@pause
