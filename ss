Traceback (most recent call last):
  File "c:\Users\donguk.koo\Desktop\유상수리비\test.py", line 19, in <module>
    rate_df = pd.read_excel("exchange_rate.xlsx")
  File "C:\Users\donguk.koo\Desktop\유상수리비\.venv\Lib\site-packages\pandas\io\excel\_base.py", line 481, in read_excel
    io = ExcelFile(
        io,
    ...<2 lines>...
        engine_kwargs=engine_kwargs,
    )
  File "C:\Users\donguk.koo\Desktop\유상수리비\.venv\Lib\site-packages\pandas\io\excel\_base.py", line 1621, in __init__
    self._reader = self._engines[engine](
                   ~~~~~~~~~~~~~~~~~~~~~^
        self._io,
        ^^^^^^^^^
        storage_options=storage_options,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        engine_kwargs=engine_kwargs,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File "C:\Users\donguk.koo\Desktop\유상수리비\.venv\Lib\site-packages\pandas\io\excel\_openpyxl.py", line 559, in __init__
    import_optional_dependency("openpyxl")
    ~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^
  File "C:\Users\donguk.koo\Desktop\유상수리비\.venv\Lib\site-packages\pandas\compat\_optional.py", line 158, in import_optional_dependency
    module = importlib.import_module(name)
  File "C:\Users\donguk.koo\AppData\Local\miniconda3\Lib\importlib\__init__.py", line 88, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
           ~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "<frozen importlib._bootstrap>", line 1387, in _gcd_import
  File "<frozen importlib._bootstrap>", line 1360, in _find_and_load
  File "<frozen importlib._bootstrap>", line 1331, in _find_and_load_unlocked
  File "<frozen importlib._bootstrap>", line 935, in _load_unlocked
  File "<frozen importlib._bootstrap_external>", line 1026, in exec_module
  File "<frozen importlib._bootstrap>", line 488, in _call_with_frames_removed
  File "C:\Users\donguk.koo\Desktop\유상수리비\.venv\Lib\site-packages\openpyxl\__init__.py", line 7, in <module>
    from openpyxl.workbook import Workbook
  File "C:\Users\donguk.koo\Desktop\유상수리비\.venv\Lib\site-packages\openpyxl\workbook\__init__.py", line 4, in <module>
    from .workbook import Workbook
  File "C:\Users\donguk.koo\Desktop\유상수리비\.venv\Lib\site-packages\openpyxl\workbook\workbook.py", line 7, in <module>
    from openpyxl.worksheet.worksheet import Worksheet
  File "C:\Users\donguk.koo\Desktop\유상수리비\.venv\Lib\site-packages\openpyxl\worksheet\worksheet.py", line 34, in <module>
    from .datavalidation import DataValidationList
  File "<frozen importlib._bootstrap>", line 1360, in _find_and_load
  File "<frozen importlib._bootstrap>", line 1331, in _find_and_load_unlocked
  File "<frozen importlib._bootstrap>", line 935, in _load_unlocked
  File "<frozen importlib._bootstrap_external>", line 1022, in exec_module
  File "<frozen importlib._bootstrap_external>", line 1118, in get_code
  File "<frozen importlib._bootstrap_external>", line 1217, in get_data
KeyboardInterrupt
