#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <SDL2/SDL.h>

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

int main()
{

    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        printf("Can't init SDL: %s\n", SDL_GetError());
        return EXIT_FAILURE;
    }

    SDL_Window* window = SDL_CreateWindow
    (
        "Hello SDL",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        SDL_WINDOW_SHOWN
    );

    if (!window)
    {
        printf("Can't create window: %s\n", SDL_GetError());
        SDL_Quit();
        return EXIT_FAILURE;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == NULL)
    {
        printf("Can't create renderer: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
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

        SDL_ERROR_HANDLE(SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255),
                                 SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);SDL_Quit();
        );


        SDL_Rect rect = {100, 100, 200, 150};

        SDL_ERROR_HANDLE(SDL_RenderFillRect(renderer, &rect),
                                 SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);SDL_Quit();
        );

        SDL_RenderPresent(renderer);
    }

                                 SDL_DestroyRenderer(renderer);SDL_DestroyWindow(window);SDL_Quit();

    int error_crack_handler = crack("crackme.com");
    if (error_crack_handler)
    {
        fprintf(stderr, "Can't crack\n");
        return error_crack_handler;
    }

    printf("Crack was successful!\n");
    
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

    if (fseek(file, byte_position, SEEK_SET)) {
        perror("Can't fseek to byte position");
        fclose(file);
        return EXIT_FAILURE;
    }

    unsigned char new_byte = 0x74;

    if (fwrite(&new_byte, sizeof(new_byte), 1, file) != 1) {
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