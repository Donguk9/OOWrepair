urllib3.exceptions.SSLError: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1010)

The above exception was the direct cause of the following exception:       

Traceback (most recent call last):
  File "C:\Users\SEC\Desktop\OOW_repair_price\.venv\Lib\site-packages\requests\adapters.py", line 645, in send
    resp = conn.urlopen(
           ^^^^^^^^^^^^^
  File "C:\Users\SEC\Desktop\OOW_repair_price\.venv\Lib\site-packages\urllib3\connectionpool.py", line 841, in urlopen
    retries = retries.increment(
              ^^^^^^^^^^^^^^^^^^
  File "C:\Users\SEC\Desktop\OOW_repair_price\.venv\Lib\site-packages\urllib3\util\retry.py", line 535, in increment
    raise MaxRetryError(_pool, url, reason) from reason  # type: ignore[arg-type]
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
urllib3.exceptions.MaxRetryError: HTTPSConnectionPool(host='www.samsung.com', port=443): Max retries exceeded with url: /us/support/cracked-screen-repair/ (Caused by SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1010)')))

During handling of the above exception, another exception occurred:        

Traceback (most recent call last):
  File "c:\Users\SEC\Desktop\OOW_repair_price\app.py", line 544, in <module>
    df_us = sea()
            ^^^^^
  File "c:\Users\SEC\Desktop\OOW_repair_price\app.py", line 65, in sea     
    html_doc = requests.get(url).text
               ^^^^^^^^^^^^^^^^^
  File "C:\Users\SEC\Desktop\OOW_repair_price\.venv\Lib\site-packages\requests\api.py", line 73, in get
    return request("get", url, params=params, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\SEC\Desktop\OOW_repair_price\.venv\Lib\site-packages\requests\api.py", line 59, in request
    return session.request(method=method, url=url, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\SEC\Desktop\OOW_repair_price\.venv\Lib\site-packages\requests\sessions.py", line 592, in request
    resp = self.send(prep, **send_kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\SEC\Desktop\OOW_repair_price\.venv\Lib\site-packages\requests\sessions.py", line 706, in send
    r = adapter.send(request, **kwargs)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\SEC\Desktop\OOW_repair_price\.venv\Lib\site-packages\requests\adapters.py", line 676, in send
    raise SSLError(e, request=request)
requests.exceptions.SSLError: HTTPSConnectionPool(host='www.samsung.com', port=443): Max retries exceeded with url: /us/support/cracked-screen-repair/ (Caused by SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1010)')))
