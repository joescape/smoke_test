[1mdiff --git a/smoke_test.py b/smoke_test.py[m
[1mindex bd967cd..4f2a42e 100644[m
[1m--- a/smoke_test.py[m
[1m+++ b/smoke_test.py[m
[36m@@ -12,7 +12,7 @@[m [mdef check_python_environment():[m
                 python_path=sys.path,[m
                 virtual_env=os.environ.get('VIRTUAL_ENV', 'Not in virtual environment'),[m
                 pyenv_version=os.environ.get('PYENV_VERSION', 'Not using pyenv'),[m
[31m-                pip_version=subprocess.check_output([sys.executable, '-m', 'pip', '--version'], text=True).strip())[m
[32m+[m[32m                pip_version=subprocess.check_output([sys.executable, '-m', 'pip', '--version']).decode().strip())[m
 [m
 def check_system_info():[m
     """Check and log system information"""[m
[36m@@ -29,7 +29,7 @@[m [mdef check_system_info():[m
 def check_wsl_specific():[m
     """Check WSL-specific information"""[m
     try:[m
[31m-        wsl_version = subprocess.check_output(['wsl', '--version'], text=True)[m
[32m+[m[32m        wsl_version = subprocess.check_output(['wsl', '--version']).decode()[m
         logger.info("WSL version information", wsl_version=wsl_version)[m
     except Exception as e:[m
         logger.error("Failed to get WSL version", error=str(e))[m
[36m@@ -89,18 +89,18 @@[m [mdef check_git_config():[m
     """Check Git configuration"""[m
     try:[m
         # Check Git version[m
[31m-        git_version = subprocess.check_output(['git', '--version'], text=True).strip()[m
[32m+[m[32m        git_version = subprocess.check_output(['git', '--version']).decode().strip()[m
         logger.info("Git version check", version=git_version)[m
         [m
         # Check Git configuration[m
         git_config = {}[m
         try:[m
[31m-            git_config['user.name'] = subprocess.check_output(['git', 'config', '--get', 'user.name'], text=True).strip()[m
[32m+[m[32m            git_config['user.name'] = subprocess.check_output(['git', 'config', '--get', 'user.name']).decode().strip()[m
         except subprocess.CalledProcessError:[m
             git_config['user.name'] = 'Not configured'[m
             [m
         try:[m
[31m-            git_config['user.email'] = subprocess.check_output(['git', 'config', '--get', 'user.email'], text=True).strip()[m
[32m+[m[32m            git_config['user.email'] = subprocess.check_output(['git', 'config', '--get', 'user.email']).decode().strip()[m
         except subprocess.CalledProcessError:[m
             git_config['user.email'] = 'Not configured'[m
             [m
