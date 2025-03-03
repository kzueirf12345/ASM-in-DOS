#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/wait.h>

#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>

#define WINDOW_WIDTH    800
#define WINDOW_HEIGHT   600

#define ERROR_HANDLE(call_func, ...)                                                                \
    do {                                                                                            \
        const int error_handler = call_func;                                                        \
        if (error_handler)                                                                          \
        {                                                                                           \
            fprintf(stderr, "Can't " #call_func "\n");                                              \
            __VA_ARGS__                                                                             \
            return error_handler;                                                                   \
        }                                                                                           \
    } while(0)

#define SDL_ERROR_HANDLE(call_func, ...)                                                            \
    do {                                                                                            \
        const int error_handler = call_func;                                                        \
        if (error_handler)                                                                          \
        {                                                                                           \
            fprintf(stderr, "Can't " #call_func ". SDL error: %s\n", SDL_GetError());               \
            __VA_ARGS__                                                                             \
            return error_handler;                                                                   \
        }                                                                                           \
    } while(0)

int crack(const char* const filename);
int do_SDL(const char* const img_filename);
int play_videos(const char* const * const videos, const size_t videos_size);

int wait_for_process(const pid_t pid);

int main()
{
    const char *videos[] = {
        "assets/video1.mp4",
        "assets/video2.mp4",
        "assets/video3.mp4",
        "assets/video4.mp4",
        "assets/video5.mp4",
    };
    size_t videos_size = sizeof(videos) / sizeof(*videos);

    pid_t pid = fork();

    if (pid == 0)
    {
        pid = fork();
        if (pid == 0)
        {
            ERROR_HANDLE(play_videos(videos, videos_size));
        }
        else if (pid > 0)
        {
            ERROR_HANDLE(do_SDL("assets/freddi.png"));
            ERROR_HANDLE(wait_for_process(pid));
        }
        else
        {
            perror("Can't fork process pid2");
            return EXIT_FAILURE;
        }
    }
    else if (pid > 0)
    {
        ERROR_HANDLE(crack("assets/crackme.com"));
        
        ERROR_HANDLE(wait_for_process(pid));

        printf("Crack was successful!\n");
    }
    else
    {
        perror("Can't fork process pid1");
        return EXIT_FAILURE;
    }
    
    return EXIT_SUCCESS;
}

int crack(const char* const filename)
{
    FILE* file = NULL;
    if (!(file = fopen(filename, "r+b")))
    {
        perror("Can't open file");
        return EXIT_FAILURE;
    }

    long byte_position = 0x3a;

    if (fseek(file, byte_position, SEEK_SET))
    {
        perror("Can't fseek to byte position");
        fclose(file);
        return EXIT_FAILURE;
    }

    unsigned char new_byte = 0x74;

    if (fwrite(&new_byte, sizeof(new_byte), 1, file) != 1)
    {
        perror("Can't fwrite new byte");
        fclose(file);
        return EXIT_FAILURE;
    }

    if (fclose(file))
    {
        perror("Can't close file");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}

int do_SDL(const char* const img_filename)
{
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        printf("Can't init SDL: %s\n", SDL_GetError());
        return EXIT_FAILURE;
    }

    if (!(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG))
    {
        printf("Can't init SDL_image: %s\n", IMG_GetError());
                                                                                         SDL_Quit();
        return EXIT_FAILURE;
    }

    SDL_DisplayMode display_mode;
    SDL_ERROR_HANDLE(SDL_GetCurrentDisplayMode(0, &display_mode),
                                                                              IMG_Quit();SDL_Quit();
    );


    SDL_Window* window = SDL_CreateWindow(
        "GovnOS present",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        SDL_WINDOW_SHOWN | SDL_WINDOW_FULLSCREEN
    );

    if (!window)
    {
        printf("Can't create window: %s\n", SDL_GetError());
                                                                              SDL_Quit();IMG_Quit();
        return EXIT_FAILURE;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer)
    {
        printf("Can't create renderer: %s\n", SDL_GetError());
                                                    SDL_DestroyWindow(window);SDL_Quit();IMG_Quit();
        return EXIT_FAILURE;
    }

    SDL_Surface* image_surface = IMG_Load(img_filename);
    if (!image_surface)
    {
        printf("Can't load img: %s\n", IMG_GetError());
                      SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);IMG_Quit();SDL_Quit();
        return EXIT_FAILURE;
    }

    SDL_Texture* image_texture = SDL_CreateTextureFromSurface(renderer, image_surface);
                                                                     SDL_FreeSurface(image_surface);
    if (!image_texture)
    {
        printf("Can't create texture img: %s\n", SDL_GetError());
                      SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);IMG_Quit();SDL_Quit();
        return EXIT_FAILURE;
    }

    bool quit = false;
    SDL_Event event;
    while (!quit)
    {
        while (SDL_PollEvent(&event)) 
        {
            if (event.type == SDL_QUIT) 
                quit = true;
        }

        SDL_ERROR_HANDLE(SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255),
                                 SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);SDL_Quit();
        );

        SDL_ERROR_HANDLE(SDL_RenderClear(renderer),
                                 SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);SDL_Quit();
        );

        SDL_RenderCopy(renderer, image_texture, NULL, NULL);

        SDL_RenderPresent(renderer);
    }

          SDL_DestroyTexture(image_texture);SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);
                                                                              IMG_Quit();SDL_Quit();

    return EXIT_SUCCESS;
}

int play_videos(const char* const * const videos, const size_t videos_size)
{
    for (size_t i = 0; i < videos_size; ++i)
    {
        pid_t pid = fork();

        if (pid == 0)
        {
            execlp("mpv", "mpv", "--no-terminal", "--geometry=50%x50%+50%+50%", videos[i], NULL);

            perror("Can't played video with mpv");
            return EXIT_FAILURE;
        } else if (pid < 0)
        {
            perror("Can't fork daughter process");
            return EXIT_FAILURE;
        }
    }

    for (size_t i = 0; i < videos_size; ++i)
    {
        if (wait(NULL) == -1)
        {
            perror("Can't wait videos process");
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}

int wait_for_process(const pid_t pid)
{
    int status;

    if (waitpid(pid, &status, 0) == -1)
    {
        fprintf(stderr, "Can't waitpid process. Pid: %d\n", status);
        return EXIT_FAILURE;
    }

    if (!WIFEXITED(status) || WEXITSTATUS(status))
    {
        fprintf(stderr, "Child process exited with an error. Parent pid: %d\n", status);
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}