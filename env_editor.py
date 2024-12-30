import streamlit as st
import os
from dotenv import load_dotenv, set_key
from pathlib import Path
import glob
import yaml
from blacklist import env_var_blacklist

def load_env_file(env_path):
    """Load environment variables from .env file"""
    env_dict = {}
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    try:
                        key, value = line.split('=', 1)
                        env_dict[key] = value if value else ""
                    except ValueError:
                        continue
    return env_dict

def save_env_file(env_dict, env_path, notify=True):
    """Save environment variables to .env file"""
    with open(env_path, 'w') as f:
        for key, value in env_dict.items():
            f.write(f"{key}={value}\n")

    if notify:
        st.success(f"Environment variables saved successfully to {env_path}!")

def save_all_env_files(env_vars_dict):
    """Save all environment files"""
    for template_file, env_vars in env_vars_dict.items():
        output_file = os.path.join(".", template_file.replace('.template', ''))
        save_env_file(env_vars, output_file, notify=False)

def load_all_env_files(template_files, from_templates=False):
    """Load all environment files"""
    env_vars_dict = {}
    for template_file in template_files:
        if from_templates:
            source_path = os.path.join("env_templates", template_file)
        else:
            source_path = os.path.join(".", template_file.replace('.template', ''))
            if not os.path.exists(source_path):
                # If .env doesn't exist, fall back to template
                source_path = os.path.join("env_templates", template_file)
        env_vars_dict[template_file] = load_env_file(source_path)
    return env_vars_dict

def get_compose_version(compose_file):
    """Extract version information from docker-compose file"""
    try:
        with open(compose_file, 'r') as f:
            compose_data = yaml.safe_load(f)
            file_version = compose_data.get('version', 'unknown')
            custom_version = compose_data.get('x-version', None)
            return {
                'file_version': file_version,
                'custom_version': custom_version,
                'filename': os.path.basename(compose_file)
            }
    except Exception as e:
        return {
            'file_version': 'error',
            'custom_version': None,
            'filename': os.path.basename(compose_file)
        }

def find_docker_compose_files():
    """Find all docker-compose files in the workspace"""
    compose_files = []
    directories = ['deployments']
    
    for directory in directories:
        if os.path.exists(directory):
            patterns = [
                os.path.join(directory, 'docker-compose*.yml'),
                os.path.join(directory, 'docker-compose*.yaml')
            ]
            for pattern in patterns:
                files = glob.glob(pattern)
                for file in files:
                    version_info = get_compose_version(file)
                    compose_files.append({
                        'path': file,
                        **version_info
                    })
    
    return sorted(compose_files, key=lambda x: x['filename'])

def get_env_templates():
    """Get all env template files"""
    template_dir = "env_templates"
    template_files = []
    if os.path.exists(template_dir):
        for file in os.listdir(template_dir):
            if file.endswith('.template'):
                template_files.append(file)
    return sorted(template_files)

def main():
    st.title("Environment Variables Editor")
    
    # Get all template files
    template_files = get_env_templates()
    
    if not template_files:
        st.error("No template files found in env_templates directory")
        return
    
    # Initialize session state for env vars if not exists
    if 'env_vars_dict' not in st.session_state:
        st.session_state.env_vars_dict = {}
    
    # Add Save All, Load All, and Reset buttons in a row
    col1, col2, col3 = st.columns(3)
    with col1:
        if st.button("Save All", type="primary"):
            save_all_env_files(st.session_state.env_vars_dict)
            st.success("All environment files saved successfully!")
    
    with col2:
        if st.button("Load All", type="secondary"):
            st.session_state.env_vars_dict = load_all_env_files(template_files, from_templates=False)
            st.success("All environment files loaded from .env files!")
    
    with col3:
        if st.button("Reset All", type="secondary"):
            st.session_state.env_vars_dict = load_all_env_files(template_files, from_templates=True)
            st.success("All environment files reset to template values, save to apply!")
    
    st.divider()
    
    # Create a tab for each template file
    tabs = st.tabs([f.replace('.template', '').replace('.env.', '').capitalize() for f in template_files])
    
    # Process each template file in its own tab
    for tab, template_file in zip(tabs, template_files):
        with tab:
            template_path = os.path.join("env_templates", template_file)
            output_file = os.path.join(".", template_file.replace('.template', ''))
            
            # Load existing env file if it exists, otherwise load from template
            if template_file not in st.session_state.env_vars_dict:
                if os.path.exists(output_file):
                    env_vars = load_env_file(output_file)
                else:
                    env_vars = load_env_file(template_path)
                st.session_state.env_vars_dict[template_file] = env_vars
            
            # Display all environment variables for this file
            st.header(f"Configuration for {template_file.replace('.template', '').replace('.env.', '').capitalize()}")
            
            # Create input fields for each environment variable
            updated_vars = {}
            for key, value in st.session_state.env_vars_dict[template_file].items():
                # Determine if the value should be treated as sensitive
                is_sensitive = any(term in key.lower() for term in ['key', 'secret', 'password', 'token', 'pw'])
                input_type = "password" if is_sensitive else "default"
                if key not in env_var_blacklist:
                    updated_vars[key] = st.text_input(
                        key,
                        value=value,
                        type=input_type,
                        key=f"{template_file}_{key}"  # Unique key for each input
                    )
                else:
                    updated_vars[key] = value
            
            st.session_state.env_vars_dict[template_file] = updated_vars
            
            # Add a save button for each file
            if st.button(f"Save {template_file.replace('.template', '')}", key=f"save_{template_file}"):
                save_env_file(updated_vars, output_file)

    # Add Docker deployment tab
    with st.expander("Docker Deployment Configuration"):
        st.header("Deployment Configuration")
        
        # Docker Hub Authentication
        st.subheader("Docker Hub Authentication")
        docker_hub_token = st.text_input(
            "Docker Hub Access Token", 
            type="password",
            help="Enter your Docker Hub access token for authentication"
        )
        
        # Docker Compose File Selection
        st.subheader("Docker Compose Configuration")
        compose_files = find_docker_compose_files()
        
        if compose_files:
            compose_options = {}
            for compose in compose_files:
                version_str = f"(Compose v{compose['file_version']}"
                if compose['custom_version']:
                    version_str += f", Version {compose['custom_version']}"
                version_str += ")"
                compose_options[compose['path']] = f"{compose['filename']} {version_str}"
            
            selected_compose = st.selectbox(
                "Select Docker Compose File",
                options=list(compose_options.keys()),
                format_func=lambda x: compose_options[x]
            )
            
            if selected_compose:
                selected_info = next(cf for cf in compose_files if cf['path'] == selected_compose)
                
                col1, col2 = st.columns(2)
                with col1:
                    st.info(f"DeploymentVersion: {selected_info['file_version']}")
                with col2:
                    if selected_info['custom_version']:
                        st.info(f"Application Version: {selected_info['custom_version']}")
                
                with open(selected_compose, 'r') as f:
                    compose_content = f.read()
                st.code(compose_content, language='yaml')
                
                if st.button("Deploy with Selected Configuration"):
                    if docker_hub_token:
                        st.success(f"Deployment initiated with {selected_info['filename']}")
                    else:
                        st.error("Please provide a Docker Hub access token before deploying")
        else:
            st.warning("No Docker Compose files found in the workspace")

if __name__ == "__main__":
    main() 