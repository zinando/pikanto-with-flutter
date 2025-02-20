import os


class FileHandler:
    """
    A class to handle basic file operations.

    Attributes:
        file_path (str): The path of the file.
        file_name (str): The name of the file.
        file_extension (str): The extension of the file.
    """

    def __init__(self, file_path = None):
        """
        Initializes the FileHandler with file attributes.

        Args:
            file_path (str): The path of the file.
        """
        if file_path:
            self.file_path = file_path
            self.file_name = os.path.basename(file_path)
            self.file_extension = os.path.splitext(self.file_name)[1]

    def save_file(self, destination):
        """
        Saves the file to a given destination. Creates the directory if it doesn't exist.

        Args:
            destination (str): The path where the file will be saved.

        Returns:
            bool: True if the file is saved successfully, False otherwise.
        """
        destination_path = os.path.join(destination, self.file_name)
        destination_dir = os.path.dirname(destination_path)

        if not os.path.exists(destination_dir):
            try:
                os.makedirs(destination_dir)
            except OSError:
                return False

        try:
            with open(destination_path, 'wb') as new_file:
                with open(self.file_path, 'rb') as original_file:
                    new_file.write(original_file.read())
            return True
        except FileNotFoundError:
            return False

    def delete_file(self, location):
        """
        Deletes a file from a given location using the filename without extension.

        Args:
            location (str): The path from which the file will be deleted.

        Returns:
            bool: True if the file is deleted successfully, False otherwise.
        """
        file_to_delete = os.path.join(location, self.file_name)
        try:
            os.remove(file_to_delete)
            return True
        except FileNotFoundError:
            return False

    def check_file_exists(self, location):
        """
        Checks if a given file name exists in the given location.

        Args:
            location (str): The path to check for the file.

        Returns:
            bool: True if the file exists, False otherwise.
        """
        file_to_check = os.path.join(location, self.file_name)
        return os.path.exists(file_to_check)

    def get_file_name_with_length(self, length):
        """
        Returns the file name with a given length of characters.

        Args:
            length (int): The desired length of the file name.

        Returns:
            str: The file name with the specified length.
        """
        return self.file_name[:length]

    @staticmethod
    def fetch_files(location):
        """
        Fetches all files within a given location.

        Args:
            location (str): The path to fetch files from.

        Returns:
            list or bool: A list of filenames if files are found, False otherwise.
        """
        if not os.path.exists(location):
            return False

        files = [f for f in os.listdir(location) if os.path.isfile(os.path.join(location, f))]

        if not files:
            return False

        return files
