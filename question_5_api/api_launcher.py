#################################################
# Question 5: Clinical Data API Launcher
#################################################

import sys
import threading
import time
import webbrowser


#################################################
# Check required packages
#################################################

try:
    import uvicorn

except ImportError:
    print(
        "\nRequired Python packages are not installed.\n"
        "Please run:\n\n"
        "    pip install -r requirements.txt\n"
    )
    sys.exit(1)


#################################################
# Open interactive documentation
#################################################

def open_docs():

    time.sleep(1.5)

    webbrowser.open(
        "http://127.0.0.1:8000/docs"
    )


#################################################
# Launch API
#################################################

if __name__ == "__main__":

    print(
        "\nStarting Clinical Trial Data API..."
    )

    print(
        "Interactive documentation will open automatically."
    )

    print(
        "If required, open: http://127.0.0.1:8000/docs"
    )

    print(
        "Press Ctrl+C to stop the API.\n"
    )

    threading.Thread(
        target=open_docs,
        daemon=True
    ).start()

    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=8000,
        reload=False
    )
